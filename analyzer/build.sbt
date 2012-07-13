import AssemblyKeys._ // put this at the top of the file
import com.github.philcali.DoccoPlugin.docco
import sbtassembly.Plugin._


// Assembly plugin settings
assemblySettings

mergeStrategy in assembly <<= (mergeStrategy in assembly) { (old) =>
    {
        case "META-INF/MANIFEST.MF" => MergeStrategy.discard
        case "META-INF/README.txt" => MergeStrategy.discard
        case "META-INF/CHANGES.txt" => MergeStrategy.discard
        case "META-INF/NOTICE" => MergeStrategy.discard
        case "META-INF/NOTICE.TXT" => MergeStrategy.discard
        case "META-INF/LICENSE" => MergeStrategy.concat
        case "META-INF/LICENSE.txt" => MergeStrategy.concat
        case "META-INF/LICENSES.txt" => MergeStrategy.concat
            case x => old(x)
    }
}

seq(doccoSettings: _*)

docco.title := "Songride Analyzer"

docco.skipEmpty := false

name := "songride-analyzer"

version := "1.0"

scalaVersion := "2.9.1"

resolvers += "Scala-Tools Maven2 Releases Repository" at "http://scala-tools.org/repo-releases"

libraryDependencies += "org.yaml" % "snakeyaml" % "1.10"

libraryDependencies += "com.github.scala-incubator.io" %% "scala-io-core" % "0.4.0"

libraryDependencies += "com.github.scala-incubator.io" %% "scala-io-file" % "0.4.0"

libraryDependencies += "com.mongodb.casbah" % "casbah_2.9.0-1" % "2.1.5.0"

libraryDependencies += "org.slf4j" % "slf4j-simple" % "1.6.4"

libraryDependencies += "ru.circumflex" % "circumflex-docco" % "2.1"

libraryDependencies += "com.foursquare" %% "rogue" % "1.1.8"

scalacOptions += "-deprecation"

scalacOptions += "-unchecked"

