module Datastore (
    connectMongo, disconnectMongo,
    countCollectionEntries, reduceTags, countRegisteredUsersDb,
    registeredUsersDb, getArtistDb
    ) where 

import Data.Either.Utils (fromRight)
import Data.List (unfoldr)
import Data.UString (u)
import Database.MongoDB

-- HelperFunctions
mongo pipe database act = access pipe master database act

connectMongo host port database username password = do 
    pipe <- runIOE (connect (readHostPort (host ++ ":" ++ port)))
    mongo pipe database (auth username password)
    return pipe

disconnectMongo = close

countCollectionEntries pipe database collection =
    mongo pipe database (count (select [] collection))
countRegisteredUsersDb pipe database collection =
    mongo pipe database (count wantedUsers)
    where wantedUsers = (select [(u "wants_statistics") =: True] collection)

registeredUsersDb pipe database collection =
    mongo pipe database ((find wantedUsers) >>= rest)
    where wantedUsers = (select [(u "wants_statistics") =: True] collection)

getArtistDb pipe database collection name =
    mongo pipe database (findOne (select [(u "name") =: name] collection))

reduceTags pipe database fromColl toColl = mongo pipe database (runMR (mapReduce fromColl tagMapFn tagReduceFn) {rOut = Output Replace toColl Nothing})
    where tagMapFn = Javascript [] (u "function() {this.top_tags.forEach (function(z) {emit(z.name, z.count);});}")
          tagReduceFn = Javascript [] (u "function (key, values) {var total = 0; for (var i = 0; i < values.length; i++) {total += values[i];} return total;}")

