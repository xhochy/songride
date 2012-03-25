package com.xhochy.songride

import com.mongodb.{ Mongo, ServerAddress }
import java.util.Map
import net.liftweb.mongodb.{MongoDB, MongoIdentifier}
import scala.collection.JavaConversions._

object RogueMongoConnection extends MongoIdentifier {
  override def jndiName = "songride"

  private var mongo: Option[Mongo] = None
  
  def connectToMongo(config: Map[_,_]) = {
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
          case _ => "songride"
        }
        val connection = new Mongo(new ServerAddress(host, port))
        mongo = Some(connection)
        MongoDB.defineDb(RogueMongoConnection, mongo.get, database)
        user.foreach({connection.getDB(database).authenticate(_, password.toArray)})
      }
    }
  }

  def disconnectFromMongo = {
    mongo.foreach(_.close)
    MongoDB.close
    mongo = None
  }
}

// vim: set ts=2 sw=2 et:
