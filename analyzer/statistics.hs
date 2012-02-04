import Data.Either.Utils as EitherUtils
import Database.MongoDB

-- Configuration
mongoHostPort = Host "127.0.0.1" (PortNumber 27117)
mongoDb = "songride"
userCollection = "users"
artistCollection = "artists"

-- HelperFunctions
mongo pipe act = access pipe master mongoDb act

listUser (Right users) = foldl folder "" names
    where names      = [ unpack y | [("username" := (String y))] <- users]
          folder a b = a ++ b ++ ", "

main = do
    -- Connect to the Database
    pipe <- runIOE (connect mongoHostPort)
    putStrLn "Generating Database Statistics…"
    -- How many artists are stored in the database?
    artistCount <- mongo pipe (count (select [] artistCollection))
    putStrLn ("Artists: " ++ (show (EitherUtils.fromRight artistCount)))
    -- How many users are stored in the database?
    userCount <- mongo pipe (count (select [] userCollection))
    putStrLn ("Users:   " ++ (show (EitherUtils.fromRight userCount)))
    -- How many (different) tags are stored in the database?
    putStrLn ("Tags:    " ++ "")
    putStrLn ""
    -- Create Statistics for all users who want them
    users <- mongo pipe (find wantedUsers {project = ["username" =: (1 :: Int), "_id" =: (0 :: Int)]} >>= rest)
    putStrLn ("Analyzing users: " ++ (listUser users))
    close pipe
    where wantedUsers =
            (select ["wants_statistics" =: True] userCollection)