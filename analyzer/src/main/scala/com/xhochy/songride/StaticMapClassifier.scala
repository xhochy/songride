package com.xhochy.songride

import org.yaml.snakeyaml.Yaml

// Add Java Map Interface so that the YAML input files could be casted 
// correctly via pattern matching.
import java.util.Map

import scala.collection.JavaConversions._
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

  def loadMapFromFiles():Map[String,String] = {
    val staticReverseMap = new HashMap[String, String]()
    // Get a list of all YAML files countaining a mapping
    Path(directory).children(IsFile).toList
      // Load the mappings into memory
      .map(f => yaml.load(f.slurpString(Codec.UTF8)))
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
      .seq.foreach(x => staticReverseMap += ((x._2.get.toString, x._1.get.toString)))
    return staticReverseMap
  }
}

// vim: set ts=2 sw=2 et:
