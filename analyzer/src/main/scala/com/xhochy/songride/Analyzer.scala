package com.xhochy.songride

import com.foursquare.rogue.Rogue._
import java.util.Map
import org.yaml.snakeyaml.Yaml
import scala.collection.JavaConversions._
import scala.collection.mutable.HashMap
import scalax.file.{ Path, PathMatcher }
import scalax.file.PathMatcher._
import scalax.io._

object Analyzer extends App {
  val yaml = new Yaml()
  val config = loadConfig("../config.yml") match {
    case Some(c) => c
    case None => failWithError("Could not load the configuration file")
  }
  RogueMongoConnection.connectToMongo(config)

  // Print statistics
  println("Artists:            %10d".format(Artist.count))
  // TODO: Tag statistics
  println("Users (all):        %10d".format(User.count))
  println("Users (registered): %10d".format(User.where(_.wantsStatistics eqs true).count()))

  // Load static tag->country mappings
  val staticMapClassifier = new StaticMapClassifier("countries")
  // Iterate over all users
  User.where(_.wantsStatistics eqs true).foreach(staticMapClassifier.updateUser)

  def failWithError(message: String) = {
    System.err.println(message)
    sys.exit(1)
  }

  def loadConfig(filename: String):Option[Map[_,_]] = {
    val configFile = Resource.fromFile(filename).slurpString(Codec.UTF8)
    yaml.load(configFile) match {
      case map:Map[_, _] => Some(map)
      case _ => None
    }
  }
}
