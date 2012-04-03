package com.xhochy.songride

import net.liftweb.mongodb.record.{ BsonRecord, BsonMetaRecord }
import net.liftweb.mongodb.record.field.{ BsonRecordListField, DateField }

class StaticMapUserStats extends BsonRecord[StaticMapUserStats] {
  def meta = StaticMapUserStats
  object countries extends BsonRecordListField(this, CountryStatistics)
  object updated_at extends DateField(this)
}

object StaticMapUserStats extends StaticMapUserStats with BsonMetaRecord[StaticMapUserStats] {
}
// vim: set ts=2 sw=2 et:
