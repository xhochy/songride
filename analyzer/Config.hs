module Config (
    loadConfig,
    datastoreDatabase, datastoreHost, datastorePort, datastoreUsername, datastorePassword, datastoreArtists, datastoreUsers, datastoreTags
    ) where 

import Data.UString
import Data.Yaml.Syck
import Data.Yaml.SyckUtils


loadConfig = parseYamlFile ("../config.yml" :: String)

datastoreConfig config = emapEntryVal config "mongo"
datastoreConfigEntry config entry = (datastoreConfig config) >>= (\x -> emapEntryVal x entry) >>= fromStringNode
datastoreDatabase config = u (maybe "" id (datastoreConfigEntry config "database"))
datastoreHost config = maybe "127.0.0.1" id (datastoreConfigEntry config "host")
datastorePort config = maybe "27017" id (datastoreConfigEntry config "port")
datastoreUsername config = u (maybe "" id (datastoreConfigEntry config "user"))
datastorePassword config = u (maybe "" id (datastoreConfigEntry config "password"))
datastoreArtists config = u (maybe "artists" id (datastoreConfigEntry config "artists_collection"))
datastoreUsers config = u (maybe "users" id (datastoreConfigEntry config "users_collection"))
datastoreTags config = u (maybe "tags" id (datastoreConfigEntry config "tags_collection"))


