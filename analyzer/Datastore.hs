module Datastore (
    connectMongo, disconnectMongo,
    countCollectionEntries, reduceTags
    ) where 

import Data.UString
import Database.MongoDB

-- HelperFunctions
mongo pipe database act = access pipe master database act

connectMongo host port database username password = do 
    pipe <- runIOE (connect (readHostPort (host ++ ":" ++ port)))
    mongo pipe database (auth username password)
    return pipe

disconnectMongo = close

countCollectionEntries pipe database collection = mongo pipe database (Database.MongoDB.count (select [] collection))

reduceTags pipe database fromColl toColl = mongo pipe database (runMR (mapReduce fromColl tagMapFn tagReduceFn) {rOut = Output Replace toColl Nothing})
    where tagMapFn = Javascript [] (u "function() {this.top_tags.forEach (function(z) {emit(z.name, z.count);});}")
          tagReduceFn = Javascript [] (u "function (key, values) {var total = 0; for (var i = 0; i < values.length; i++) {total += values[i];} return total;}")

