import Data.Either.Utils as EitherUtils
import Database.MongoDB
import System.Directory as Directory

-- Configuration
mongoHostPort = Host "127.0.0.1" (PortNumber 27117)
mongoDb = "songride"
userCollection = "users"
artistCollection = "artists"

-- HelperFunctions
mongo pipe act = access pipe master mongoDb act

listUser (Right users) = foldl folder "" names
    where names      = [ unpack y | [("username" := (String y))] <- users]
          folder a b = a ++ b ++ "\n "

main = do
    -- Connect to the Database
    pipe <- runIOE (connect mongoHostPort)
    files <- Directory.getDirectoryContents "countries"
    print (map stripYML (filter (\x -> not (elem x [".",".."])) files))
    putStrLn "Generating Database Statistics…"
    -- How many artists are stored in the database?
    artistCount <- mongo pipe (count (select [] artistCollection))
    putStrLn ("Artists: " ++ (show (EitherUtils.fromRight artistCount)))
    -- How many users are stored in the database?
    userCount <- mongo pipe (count (select [] userCollection))
    putStrLn ("Users:   " ++ (show (EitherUtils.fromRight userCount)))
    -- How many (different) tags are stored in the database?
    tagMR <- mongo pipe (runMR (mapReduce artistCollection tagMapFn tagReduceFn) {rOut = Output Replace "mr1out" Nothing})
    tagCount <- mongo pipe (count (select [] "mr1out"))
    putStrLn ("Tags:    " ++ show(EitherUtils.fromRight tagCount))
    putStrLn ""
    -- Create Statistics for all users who want them
    users <- mongo pipe (find wantedUsers {project = ["username" =: (1 :: Int), "_id" =: (0 :: Int)]} >>= rest)
    putStrLn ("Analyzing users: \n " ++ (listUser users))
    close pipe
    where wantedUsers =
            (select ["wants_statistics" =: True] userCollection)
          tagMapFn = Javascript [] "function() {this.top_tags.forEach (function(z) {emit(z.name, z.count);});}"
          tagReduceFn = Javascript [] "function (key, values) {var total = 0; for (var i = 0; i < values.length; i++) {total += values[i];} return total;}"
          stripYML s = take ((length s) - 4) s
