import qualified Data.Yaml.Syck as Yaml

import Config
import Data.Either.Utils
import Datastore

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

reduceTasks config mongoPipe = do
    reduceTags mongoPipe database artistColl tagColl
    where database = datastoreDatabase config
          artistColl = datastoreArtists config
          tagColl = datastoreTags config

main = do
    -- Load configuration
    config <- loadConfig
    mongoPipe <- connectDB config
    reduceTasks config mongoPipe
    statistics config mongoPipe
    disconnectMongo mongoPipe

statistics config mongoPipe = do
    putStrLn "Generating Database Statistics…"
    -- How many artists are stored in the database?
    artistCount <- countArtists config mongoPipe
    putStrLn ("Artists: " ++ (show (fromRight artistCount)))
    -- How many users are stored in the database?
    userCount <- countUsers config mongoPipe
    putStrLn ("Users:   " ++ (show (fromRight userCount)))
    -- How many (different) tags are stored in the database?
    tagCount <- countTags config mongoPipe
    putStrLn ("Tags:    " ++ show(fromRight tagCount))
    putStrLn ""


-- TODO: 
    -- Create Statistics for all users who want them
    {- users <- mongo pipe (M.find wantedUsers {M.project = ["username" M.=: (1 :: Int), "_id" M.=: (0 :: Int)]} >>= M.rest)
    putStrLn ("Analyzing users: \n " ++ (listUser users))
    where wantedUsers = (M.select ["wants_statistics" M.=: True] userCollection)
          stripYML s = take ((length s) - 4) s -}
