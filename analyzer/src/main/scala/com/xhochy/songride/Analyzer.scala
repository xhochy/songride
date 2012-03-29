package com.xhochy.songride

import com.foursquare.rogue.Rogue._
import com.mongodb.casbah.Imports._
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
  val mongoDB = connectToMongo(config) match {
    case Some(db) => db
    case None => failWithError("Could not connect to the database")
  }
  val artistsDB = mongoDB("artists")
  val usersDB = mongoDB("users")

  // Print statistics
  println("Artists:            %10d".format(Artist.count))
  // TODO: Tag statistics
  println("Users (all):        %10d".format(User.count))
  println("Users (registered): %10d".format(User.where(_.wantsStatistics eqs true).count()))

  // Load static tag->country mappings
  val staticMapClassifier = new StaticMapClassifier("countries")
  // Iterate over all users
  User.where(_.wantsStatistics eqs true).foreach(record => {
    println(record)
  })
  sys.exit(0)
  usersDB.find(MongoDBObject("wants_statistics" -> true)).foreach(user =>
      user.getAs[BasicDBList]("artists").foreach(some => some.foreach(artist =>
          artist.asInstanceOf[BasicDBObject].getAs[String]("name").foreach(name =>
            artist.asInstanceOf[BasicDBObject].getAs[Int]("count").foreach(count => {
                artistsDB.findOne(MongoDBObject("name" -> name)).foreach(art => art.getAs[BasicDBList]("top_tags").foreach(someTags =>
                  someTags.foreach(tag => println(tag))
                ))
              sys.exit(0)
          }
          // TODO
          // Get database entry
          // If there is no static classification or an old one --> update
    )))))

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

  def connectToMongo(config: Map[_,_]):Option[MongoDB] = {
    config.get("mongo") match {
      case map:Map[_,_] => {
        val host = map.get("host") match {
          case s:String => s
          case _ => "localhost"
        }
        val port = map.get("port") match {
          case s:String => s.toInt
          case i:Int => i
          case _ => 27017
        }
        val user = map.get("user") match {
          case s:String => Some(s)
          case _ => None
        }
        val password = map.get("password") match {
          case s:String => s
          case _ => ""
        }
        val database = map.get("database") match {
          case s:String => s
          case _ => return None
        }
        val connection = MongoConnection(host, port)
        val db = connection(database)
        user.map({db.authenticate(_, password)}) match {
            case Some(false) => return None
            case _ => true
        }
        return Some(db)
      }
      case _ => None
    }
  }
}
