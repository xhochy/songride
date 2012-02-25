import qualified Control.Monad as Monad
import qualified Data.Either.Utils as EitherUtils
import qualified Data.Yaml.Syck as Yaml
import qualified Data.List as List
import qualified Data.UString as U
import qualified Database.MongoDB as M
import qualified System.Directory as Directory

-- Configuration
mongoDb = "songride"
userCollection = "users"
artistCollection = "artists"

-- HelperFunctions
mongo pipe act = M.access pipe M.master mongoDb act

listUser (Right users) = foldl folder "" names
    where names      = [ M.unpack y | [("username" M.:= (M.String y))] <- users]
          folder a b = a ++ b ++ "\n "

mongoConfig config = Yaml.emapEntryVal config "mongo"
mongoConfigEntry config entry = (mongoConfig config) >>= (\x -> Yaml.emapEntryVal x entry) >>= Yaml.fromStringNode
mongoDatabase config = mongoConfigEntry config "database"
mongoHostPort config = M.readHostPort (host ++ ":" ++ port)
    where port = maybe "27017" id (mongoConfigEntry config "port")
          host = maybe "127.0.0.1" id (mongoConfigEntry config "host")
mongoUsername config = U.u (maybe "" id (mongoConfigEntry config "user"))
mongoPassword config = U.u (maybe "" id (mongoConfigEntry config "password"))
mongoArtists config = U.u (maybe "artists" id (mongoConfigEntry config "artists_collection"))

main = do
    -- Load configuration
    config <- Yaml.parseYamlFile ("../config.yml" :: String)
    -- Connect to the Database
    pipe <- M.runIOE (M.connect (mongoHostPort config))
    -- Authenticate
    mongo pipe (M.auth (mongoUsername config) (mongoPassword config))
    -- Load the static tag->country mappings
    -- files <- Directory.getDirectoryContents "countries"
    -- print (map stripYML (filter (\x -> not (elem x [".",".."])) files))
    -- TODO
    putStrLn "Generating Database Statistics…"
    -- How many artists are stored in the database?
    artistCount <- mongo pipe (M.count (M.select [] (mongoArtists config)))
    putStrLn ("Artists: " ++ (show (EitherUtils.fromRight artistCount)))
    -- How many users are stored in the database?
    userCount <- mongo pipe (M.count (M.select [] userCollection))
    putStrLn ("Users:   " ++ (show (EitherUtils.fromRight userCount)))
    -- How many (different) tags are stored in the database?
    tagMR <- mongo pipe (M.runMR (M.mapReduce artistCollection tagMapFn tagReduceFn) {M.rOut = M.Output M.Replace "mr1out" Nothing})
    tagCount <- mongo pipe (M.count (M.select [] "mr1out"))
    putStrLn ("Tags:    " ++ show(EitherUtils.fromRight tagCount))
    putStrLn ""
    -- Create Statistics for all users who want them
    users <- mongo pipe (M.find wantedUsers {M.project = ["username" M.=: (1 :: Int), "_id" M.=: (0 :: Int)]} >>= M.rest)
    putStrLn ("Analyzing users: \n " ++ (listUser users))
    M.close pipe
    where wantedUsers = (M.select ["wants_statistics" M.=: True] userCollection)
          tagMapFn = M.Javascript [] "function() {this.top_tags.forEach (function(z) {emit(z.name, z.count);});}"
          tagReduceFn = M.Javascript [] "function (key, values) {var total = 0; for (var i = 0; i < values.length; i++) {total += values[i];} return total;}"
          stripYML s = take ((length s) - 4) s

