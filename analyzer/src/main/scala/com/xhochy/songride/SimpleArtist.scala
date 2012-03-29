package com.xhochy.songride

import net.liftweb.mongodb.record.{ BsonRecord, BsonMetaRecord }
import net.liftweb.record.field.{ StringField, LongField }

class SimpleArtist extends BsonRecord[SimpleArtist] {
  def meta = SimpleArtist
  object name extends StringField(this, 1024)
  object count extends LongField(this)
}

object SimpleArtist extends SimpleArtist with BsonMetaRecord[SimpleArtist] {
}

// vim: set ts=2 sw=2 et:
