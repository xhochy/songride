package com.xhochy.songride

import net.liftweb.mongodb.record.{ BsonRecord, BsonMetaRecord }
import net.liftweb.record.field.{ DoubleField, StringField }

class CountryStatistics extends BsonRecord[CountryStatistics] {
  def meta = CountryStatistics
  object name extends StringField(this, 1024)
  object percentage extends DoubleField(this)
}

object CountryStatistics extends CountryStatistics with BsonMetaRecord[CountryStatistics] {
}

// vim: set ts=2 sw=2 et:
