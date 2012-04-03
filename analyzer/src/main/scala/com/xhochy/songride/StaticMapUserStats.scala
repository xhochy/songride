package com.xhochy.songride

import net.liftweb.mongodb.record.{ BsonRecord, BsonMetaRecord }
import net.liftweb.record.field.{ DoubleField, StringField }

class StaticMapUserStats extends BsonRecord[StaticMapUserStats] {
  def meta = StaticMapUserStats
  object country extends StringField(this, 1024)
  object percentage extends DoubleField(this)
}

object StaticMapUserStats extends StaticMapUserStats with BsonMetaRecord[StaticMapUserStats] {
}
// vim: set ts=2 sw=2 et:
