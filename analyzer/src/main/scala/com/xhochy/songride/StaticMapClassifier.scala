package com.xhochy.songride

import org.yaml.snakeyaml.Yaml

// Add Java Map Interface so that the YAML input files could be casted 
// correctly via pattern matching.
import java.util.{Date, Map}

import scala.collection.JavaConversions.asScalaBuffer
import scala.collection.mutable.HashMap

import scalax.file.{ Path, PathMatcher }
import scalax.file.PathMatcher._
import scalax.io._

/*!# Static Map Classifer

  This classifier is based on mappings from tags to a country.
 
  There is a YAML file for each country that should be treated as a class.
  These files contain tags that are commonly used for a country.

  For each artist all tags are mapped to their country and the counts
  of all tags that belong to the same country are accumulated. The country
  with the highest accumulated count is choosen as the most likely country
  where this artist may come from.
 */ 
class StaticMapClassifier(directory: String) {
  val yaml = new Yaml()
  val reverseMap = loadMapFromFiles()

  val UPDATE_FREQUENCY = 1000*60*60*24*7 // Update every 7 days

  def loadMapFromFiles():scala.collection.mutable.Map[String,String] = {
    val staticReverseMap = new HashMap[String, String]()
    // Get a list of all YAML files countaining a mapping
    Path(directory).children(IsFile).toList
      // Load the mappings into memory
      .map(f => yaml.load(f.string(Codec.UTF8)))
      // Cast all parsed files to Map[_,_]
      .map[Option[Map[_,_]], List[Option[Map[_,_]]]](_ match {
          case map:Map[_,_] => Some[Map[_,_]](map)
          case _ => None
      })
      // All files are loaded into the main memory
      // From now we could work on them in parallel
      .par
      // Only work on the mappings that were successfully parsed
      .filter(!_.isEmpty).map(_.get)
      // Convert the YAML nodes to (Option, Option)-Tuples
      .map(y => {
        val country = y.get(":country") match {
          case s:String => Some(s)
          case _ => None
        }
        val tags = y.get(":tags") match {
          case l:java.util.List[_] => Some(l.map(_.toString))
          case _ => None
        }
        (country, tags)
      })
      // Ignore tuples were the country or the tags couldn't be parsed
      .filter(x => (!x._1.isEmpty) && (!x._2.isEmpty))
      // Get the values of the Options in the reverse map.
      // Insert sequentially as the HashMap is a single thread implementation
      .seq.foreach(x =>
        x._2.get.foreach(tag =>
          staticReverseMap.+=((tag, x._1.get.toString))))
    return staticReverseMap
  }

  // Update the classification of all artists heard by this user and
  // accumulate the country counts.
  def updateUser(user: User) {
    // Check if statistics need an update
    val len = user.staticMapClassification.get.countries.get.length
    val time = user.staticMapClassification.get.updated_at.get.getTime
    if ((new Date).getTime - UPDATE_FREQUENCY < time && len > 0) return
    // Statistics need to be updated
    val stats = user.artists.get.map(record => record.getDetailed() match {
        case Some(artist) => (updateArtist(artist), record.count.get)
        case None => ("Unknown", record.count.get)
      })
      // Aggregate playcounts for each country
      .groupBy(_._1).map(x => (x._1, x._2.map(_._2).sum))
    // Compute total number of plays
    val playcount = stats.foldLeft(0L)((r, x) => x._2 + r)
    // Map playcounts to percentages
    val relativeStats = stats.mapValues[Double](_*1.0D / playcount)
    // Save to the database
    user.staticMapClassification(StaticMapUserStats.createRecord.updated_at(new Date)
      .countries(relativeStats.toList.map(x => {
        CountryStatistics.createRecord.name(x._1).percentage(x._2)
      })))
    user.save
  }

  // Check if the classification of an artist should be updated and return the
  // latest classification result.
  def updateArtist(artist: Artist):String = {
    // TODO: Check if there is already a classification available
    // Determine the scores of possible countries
    val maximumLikely = artist.top_tags.get
      .map(tag => (reverseMap.get(tag.name.get), tag.count.get))
      // Strip all tags that do not resolve to a country
      .filter(!_._1.isEmpty).map(x => (x._1.get, x._2))
      // Aggregate scores for each country
      .groupBy(_._1).map(x => (x._1, x._2.map(_._2).sum))
      // Add an Unknown entry so that we always have a entry in the list
      .+(("Unknown", 0L))
      // Get the country with the highest
      .maxBy(_._2)
    // TODO: Save classification in the database
    return maximumLikely._1
  }
}

// vim: set ts=2 sw=2 et:
