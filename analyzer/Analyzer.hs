import qualified Data.Yaml.Syck as Yaml

import Config
import Data.Bson (look, Value(..), Document, cast', cast, Field(..))
import Data.Either.Utils
import Data.Map (Map)
import qualified Data.Map as Map
import Data.Maybe (fromJust, mapMaybe, catMaybes)
import Data.UString (u)
import Data.Yaml.Syck
import Data.Yaml.SyckUtils
import Datastore
import System.Directory

connectDB config = connectMongo host port database username password
    where host = datastoreHost config
          port = datastorePort config
          database = datastoreDatabase config
          username = datastoreUsername config
          password = datastorePassword config

countArtists config mongoPipe = countCollectionEntries mongoPipe database collection
    where database = datastoreDatabase config
          collection = datastoreArtists config  

countUsers config mongoPipe = countCollectionEntries mongoPipe database collection
    where database = datastoreDatabase config
          collection = datastoreUsers config

countTags config mongoPipe = countCollectionEntries mongoPipe database collection
    where database = datastoreDatabase config
          collection = datastoreTags config

countRegisteredUsers config mongoPipe = countRegisteredUsersDb mongoPipe database collection
    where database = datastoreDatabase config
          collection = datastoreUsers config

reduceTasks config mongoPipe = do
    reduceTags mongoPipe database artistColl tagColl
    where database = datastoreDatabase config
          artistColl = datastoreArtists config
          tagColl = datastoreTags config

statistics config mongoPipe = do
    putStrLn "Generating Database Statistics…"
    -- How many artists are stored in the database?
    artistCount <- countArtists config mongoPipe
    putStrLn ("Artists: " ++ (show (fromRight artistCount)))
    -- How many users are stored in the database?
    userCount <- countUsers config mongoPipe
    putStrLn ("Users (all):   " ++ (show (fromRight userCount)))
    regUserCount <- countRegisteredUsers config mongoPipe
    putStrLn ("Users (registered):" ++ (show (fromRight regUserCount)))
    -- How many (different) tags are stored in the database?
    tagCount <- countTags config mongoPipe
    putStrLn ("Tags:    " ++ show(fromRight tagCount))
    putStrLn ""

parseCountryFile filename = do
    yaml <- parseYamlFile ("countries/" ++ filename)
    return (country yaml, tags yaml)
    where tags y = fromJust ((emapEntryVal y ":tags") >>= fromStringSeqNode)
          country y = fromJust ((emapEntryVal y ":country") >>= fromStringNode)

loadStaticClassificationMap = do
    files <- getDirectoryContents "countries"
    parsedFiles <- mapM parseCountryFile (stripNonYmlFiles files)
    return (Map.fromList parsedFiles)
    where stripNonYmlFiles = (filter endsInYml)
          endsInYml s = (take 4 (reverse s)) == reverse ".yml"

registeredUsers config mongoPipe = registeredUsersDb mongoPipe database collection
    where database = datastoreDatabase config
          collection = datastoreUsers config

staticArtistClassification config pipe staticMap artistName = do
    artist <- fmap fromRight (getArtistDb pipe database collection artistName)
    return (top_tags artist) 
    where database = datastoreDatabase config
          collection = datastoreArtists config
          top_tags a = fmap (map unwrapTag) ((fmap (mapMaybe cast) ((a >>= (look (u "top_tags")) >>= cast) :: Maybe [Value])) :: Maybe [Document])
          unwrapTag t = ((look (u "name") t) >>= cast, (look (u "count") t)) >>= cast :: (Maybe String, Maybe Int)

staticMapClassifyUser config pipe staticMap user = staticArtistClassification config pipe staticMap (head (fromJust getArtistNames))
    where artists = (fmap (mapMaybe cast') ((((look (u "artists") user) >>= cast') :: Maybe [Value]))) :: Maybe [Document]
          getArtistNames = (fmap (mapMaybe cast) ((fmap (mapMaybe (look (u "name"))) artists) :: Maybe [Value])) :: Maybe [String]
-- TODO
-- Get artists: foreach:
-- -> is classified -> continue with next
-- -> not classified
-- --> get tags and compute maximum likely country
-- Accumulate countries by artist playcounts

staticMapClassification config mongoPipe = do
    countries <- loadStaticClassificationMap
    users <- (registeredUsers config mongoPipe)
    classification <- head (map (staticMapClassifyUser config mongoPipe countries) (fromRight users))
    print classification
    return classification

main = do
    -- Load configuration
    config <- loadConfig
    mongoPipe <- connectDB config
    -- reduceTasks config mongoPipe
    statistics config mongoPipe
    staticMapClassification config mongoPipe

