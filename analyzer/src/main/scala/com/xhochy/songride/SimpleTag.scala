package com.xhochy.songride

import net.liftweb.mongodb.record.{ BsonRecord, BsonMetaRecord }
import net.liftweb.record.field.{ StringField, LongField }

class SimpleTag extends BsonRecord[SimpleTag] {
  def meta = SimpleTag

  object name extends StringField(this, 1024)
  object count extends LongField(this)
}

object SimpleTag extends SimpleTag with BsonMetaRecord[SimpleTag]

// vim: set ts=2 sw=2 et:
