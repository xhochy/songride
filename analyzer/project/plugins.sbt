// SBT Eclipse
resolvers += Classpaths.typesafeResolver

resolvers += "sonatype-public" at "https://oss.sonatype.org/content/groups/public"

addSbtPlugin("com.typesafe.sbteclipse" % "sbteclipse-plugin" % "2.0.0-M2")

// scct
// addSbtPlugin("ch.craven" % "scct-plugin" % "0.2.1")

// sbt-assembly
resolvers += Resolver.url("artifactory", url("http://scalasbt.artifactoryonline.com/scalasbt/sbt-plugin-releases"))(Resolver.ivyStylePatterns)

addSbtPlugin("com.eed3si9n" % "sbt-assembly" % "0.8.3")

addSbtPlugin("com.github.philcali" % "sbt-cx-docco" % "0.1.2")
