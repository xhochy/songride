package com.xhochy.songride

import net.liftweb.mongodb.record.{ MongoMetaRecord, MongoRecord, MongoId }
import net.liftweb.mongodb.record.field.BsonRecordListField
import net.liftweb.record.field.StringField

class Artist extends MongoRecord[Artist] with MongoId[Artist] {
  def meta = Artist
  object name extends StringField(this, 1024)
  object top_tags extends BsonRecordListField(this, SimpleTag)
}

object Artist extends Artist with MongoMetaRecord[Artist] {
  override def collectionName = "artists"
  override def mongoIdentifier = RogueMongoConnection
}

// vim: set ts=2 sw=2 et:
