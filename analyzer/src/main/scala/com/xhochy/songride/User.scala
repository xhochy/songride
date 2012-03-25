package com.xhochy.songride

import net.liftweb.mongodb.record.{ MongoMetaRecord, MongoRecord, MongoId }
// import net.liftweb.mongodb.record.field.BsonRecordListField
import net.liftweb.record.field.{ StringField, BooleanField }

class User extends MongoRecord[User] with MongoId[User] {
  def meta = User
  object name extends StringField(this, 1024)
  object wantsStatistics extends BooleanField(this) { override def name = "wants_statistics" }
}

object User extends User with MongoMetaRecord[User] {
  override def collectionName = "users"
  override def mongoIdentifier = RogueMongoConnection
}

// vim: set ts=2 sw=2 et:
