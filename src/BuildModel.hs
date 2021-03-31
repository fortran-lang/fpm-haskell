module BuildModel where

import           Control.Applicative            ( (<|>) )
import           Control.Monad                  ( when )
import           Data.Char                      ( isAsciiLower
                                                , isDigit
                                                , toLower
                                                )
import           Data.Maybe                     ( fromMaybe
                                                , mapMaybe
                                                )
import           Data.List                      ( intercalate )
import           System.FilePath                ( (</>)
                                                , (<.>)
                                                , splitDirectories
                                                )
import           Text.ParserCombinators.ReadP   ( ReadP
                                                , char
                                                , eof
                                                , many
                                                , many1
                                                , option
                                                , readP_to_S
                                                , satisfy
                                                , skipSpaces
                                                , string
                                                )

data LineContents =
    ProgramDeclaration
  | ModuleDeclaration String
  | ModuleUsed String
  | ModuleSubprogramDeclaration
  | SubmoduleDeclaration String String String
  | Other

data RawSource = RawSource {
    rawSourceFilename :: FilePath
  , rawSourceContents :: String
}

data Source =
  Program
    { programSourceFileName :: FilePath
    , programObjectFileName :: FilePath -> FilePath
    , programModulesUsed :: [String]
    }
  | Module
    { moduleSourceFileName :: FilePath
    , moduleObjectFileName :: FilePath -> FilePath
    , moduleModulesUsed :: [String]
    , moduleName :: String
    , moduleProducesSmod :: Bool
    }
  | Submodule
    { submoduleSourceFileName :: FilePath
    , submoduleObjectFileName :: FilePath -> FilePath
    , submoduleModulesUsed :: [String]
    , submoduleBaseModuleName :: String
    , submoduleParentName :: String
    , submoduleName :: String
    }

data CompileTimeInfo = CompileTimeInfo {
    compileTimeInfoSourceFileName :: FilePath
  , compileTimeInfoObjectFileProduced :: FilePath
  , compileTimeInfoOtherFilesProduced :: [FilePath]
  , compileTimeInfoDirectDependencies :: [FilePath]
}

data AvailableModule = AvailableModule {
    availableModuleName :: String
  , availableModuleFile :: FilePath
}

processRawSource :: RawSource -> Source
processRawSource rawSource =
  let
    sourceFileName = rawSourceFilename rawSource
    parsedContents = parseContents rawSource
    objectFileName =
      \bd -> bd </> (pathSeparatorsToUnderscores sourceFileName) <.> "o"
    modulesUsed = getModulesUsed parsedContents
  in
    if hasProgramDeclaration parsedContents
      then Program { programSourceFileName = sourceFileName
                   , programObjectFileName = objectFileName
                   , programModulesUsed    = modulesUsed
                   }
      else if hasModuleDeclaration parsedContents
        then Module
          { moduleSourceFileName = sourceFileName
          , moduleObjectFileName = objectFileName
          , moduleModulesUsed    = modulesUsed
          , moduleName           = getModuleName parsedContents
          , moduleProducesSmod   = hasModuleSubprogramDeclaration parsedContents
          }
        else if hasSubmoduleDeclaration parsedContents
          then Submodule
            { submoduleSourceFileName = sourceFileName
            , submoduleObjectFileName = objectFileName
            , submoduleModulesUsed    = modulesUsed
            , submoduleBaseModuleName = getSubmoduleBaseModuleName
                                          parsedContents
            , submoduleParentName     = getSubmoduleParentName parsedContents
            , submoduleName           = getSubmoduleName parsedContents
            }
          else undefined

getAvailableModules :: [Source] -> FilePath -> [AvailableModule]
getAvailableModules sources buildDirectory = mapMaybe maybeModule sources
 where
  maybeModule m@(Module{}) =
      let mName = moduleName m
          modFile = buildDirectory </> mName <.> "mod"
      in Just $ AvailableModule { availableModuleName = mName, availableModuleFile = modFile }
  maybeModule _            = Nothing

getAllObjectFiles :: FilePath -> [Source] -> [FilePath]
getAllObjectFiles buildDirectory sources = map getObjectFile sources
 where
  getObjectFile p@(Program{}  ) = (programObjectFileName p) buildDirectory
  getObjectFile m@(Module{}   ) = (moduleObjectFileName m) buildDirectory
  getObjectFile s@(Submodule{}) = (submoduleObjectFileName s) buildDirectory

getSourceFileName :: Source -> FilePath
getSourceFileName p@(Program{}  ) = programSourceFileName p
getSourceFileName m@(Module{}   ) = moduleSourceFileName m
getSourceFileName s@(Submodule{}) = submoduleSourceFileName s

constructCompileTimeInfo :: Source -> [AvailableModule] -> FilePath -> CompileTimeInfo
constructCompileTimeInfo p@(Program{}) availableModules buildDirectory =
  CompileTimeInfo
    { compileTimeInfoSourceFileName     = programSourceFileName p
    , compileTimeInfoObjectFileProduced = (programObjectFileName p)
                                            buildDirectory
    , compileTimeInfoOtherFilesProduced = []
    , compileTimeInfoDirectDependencies = map
      (\am -> availableModuleFile am)
      (filter (\am -> (availableModuleName am) `elem` (programModulesUsed p)) availableModules)
    }
constructCompileTimeInfo m@(Module{}) availableModules buildDirectory =
  CompileTimeInfo
    { compileTimeInfoSourceFileName     = moduleSourceFileName m
    , compileTimeInfoObjectFileProduced = (moduleObjectFileName m)
                                            buildDirectory
    , compileTimeInfoOtherFilesProduced =
      (buildDirectory </> moduleName m <.> "mod") : if moduleProducesSmod m
        then [buildDirectory </> moduleName m <.> "smod"]
        else []
    , compileTimeInfoDirectDependencies = map
      (\am -> availableModuleFile am)
      (filter (\am -> (availableModuleName am) `elem` (moduleModulesUsed m)) availableModules)
    }
constructCompileTimeInfo s@(Submodule{}) availableModules buildDirectory =
  CompileTimeInfo
    { compileTimeInfoSourceFileName     = submoduleSourceFileName s
    , compileTimeInfoObjectFileProduced = (submoduleObjectFileName s)
                                            buildDirectory
    , compileTimeInfoOtherFilesProduced = [ buildDirectory
                                            </> submoduleBaseModuleName s
                                            ++  "@"
                                            ++  submoduleName s
                                            <.> "smod"
                                          ]
    , compileTimeInfoDirectDependencies =
      (buildDirectory </> submoduleParentName s <.> "smod")
        : (map (\am -> availableModuleFile am)
               (filter (\am -> (availableModuleName am) `elem` (submoduleModulesUsed s)) availableModules)
          )
    }

pathSeparatorsToUnderscores :: FilePath -> FilePath
pathSeparatorsToUnderscores fileName =
  intercalate "_" (splitDirectories fileName)

parseContents :: RawSource -> [LineContents]
parseContents rawSource =
  let fileLines = lines $ rawSourceContents rawSource
  in  map parseFortranLine fileLines

hasProgramDeclaration :: [LineContents] -> Bool
hasProgramDeclaration parsedContents = case filter f parsedContents of
  x : _ -> True
  _     -> False
 where
  f lc = case lc of
    ProgramDeclaration -> True
    _                  -> False

hasModuleDeclaration :: [LineContents] -> Bool
hasModuleDeclaration parsedContents = case filter f parsedContents of
  x : _ -> True
  _     -> False
 where
  f lc = case lc of
    ModuleDeclaration{} -> True
    _                   -> False

hasSubmoduleDeclaration :: [LineContents] -> Bool
hasSubmoduleDeclaration parsedContents = case filter f parsedContents of
  x : _ -> True
  _     -> False
 where
  f lc = case lc of
    SubmoduleDeclaration{} -> True
    _                      -> False

hasModuleSubprogramDeclaration :: [LineContents] -> Bool
hasModuleSubprogramDeclaration parsedContents = case filter f parsedContents of
  x : _ -> True
  _     -> False
 where
  f lc = case lc of
    ModuleSubprogramDeclaration -> True
    _                           -> False

getModulesUsed :: [LineContents] -> [String]
getModulesUsed = mapMaybe contentToMaybeModuleName
 where
  contentToMaybeModuleName content = case content of
    ModuleUsed moduleName -> Just moduleName
    _                     -> Nothing

getModuleName :: [LineContents] -> String
getModuleName pc = head $ mapMaybe contentToMaybeModuleName pc
 where
  contentToMaybeModuleName content = case content of
    ModuleDeclaration moduleName -> Just moduleName
    _                            -> Nothing

getSubmoduleBaseModuleName :: [LineContents] -> String
getSubmoduleBaseModuleName pc = head $ mapMaybe contentToMaybeModuleName pc
 where
  contentToMaybeModuleName content = case content of
    SubmoduleDeclaration baseModuleName submoduleParentName submoduleName ->
      Just baseModuleName
    _ -> Nothing

getSubmoduleParentName :: [LineContents] -> String
getSubmoduleParentName pc = head $ mapMaybe contentToMaybeModuleName pc
 where
  contentToMaybeModuleName content = case content of
    SubmoduleDeclaration baseModuleName submoduleParentName submoduleName ->
      Just submoduleParentName
    _ -> Nothing

getSubmoduleName :: [LineContents] -> String
getSubmoduleName pc = head $ mapMaybe contentToMaybeModuleName pc
 where
  contentToMaybeModuleName content = case content of
    SubmoduleDeclaration baseModuleName submoduleParentName submoduleName ->
      Just submoduleName
    _ -> Nothing

readFileLinesIO :: FilePath -> IO [String]
readFileLinesIO file = do
  contents <- readFile file
  return $ lines contents

parseFortranLine :: String -> LineContents
parseFortranLine line =
  let line'  = map toLower line
      result = readP_to_S doFortranLineParse line'
  in  getResult result
 where
  getResult (_ : (contents, _) : _) = contents
  getResult [(contents, _)        ] = contents
  getResult []                      = Other

doFortranLineParse :: ReadP LineContents
doFortranLineParse = option Other fortranUsefulContents

fortranUsefulContents :: ReadP LineContents
fortranUsefulContents =
  programDeclaration
    <|> moduleSubprogramDeclaration
    <|> moduleDeclaration
    <|> submoduleDeclaration
    <|> useStatement

programDeclaration :: ReadP LineContents
programDeclaration = do
  skipSpaces
  _ <- string "program"
  skipAtLeastOneWhiteSpace
  _ <- validIdentifier
  return ProgramDeclaration

moduleDeclaration :: ReadP LineContents
moduleDeclaration = do
  skipSpaces
  _ <- string "module"
  skipAtLeastOneWhiteSpace
  moduleName <- validIdentifier
  when (moduleName == "procedure") (fail "")
  skipSpaceCommentOrEnd
  return $ ModuleDeclaration moduleName

submoduleDeclaration :: ReadP LineContents
submoduleDeclaration = do
  skipSpaces
  _       <- string "submodule"
  parents <- submoduleParents
  let parentName = case parents of
        (baseModule : []) -> baseModule
        (multiple       ) -> (head multiple) ++ "@" ++ (last multiple)
  skipSpaces
  name <- validIdentifier
  skipSpaceCommentOrEnd
  return $ SubmoduleDeclaration (head parents) parentName name

submoduleParents :: ReadP [String]
submoduleParents = do
  skipSpaces
  _ <- char '('
  skipSpaces
  firstParent      <- validIdentifier
  remainingParents <- many
    (do
      skipSpaces
      _ <- char ':'
      skipSpaces
      name <- validIdentifier
      return name
    )
  skipSpaces
  _ <- char ')'
  return $ firstParent : remainingParents

useStatement :: ReadP LineContents
useStatement = do
  skipSpaces
  _ <- string "use"
  skipAtLeastOneWhiteSpace
  modName <- validIdentifier
  skipSpaceCommaOrEnd
  return $ ModuleUsed modName

moduleSubprogramDeclaration :: ReadP LineContents
moduleSubprogramDeclaration = do
  skipSpaces
  skipProcedureQualifiers
  _ <- string "module"
  skipAtLeastOneWhiteSpace
  _ <- string "function" <|> string "subroutine"
  skipAtLeastOneWhiteSpace
  return $ ModuleSubprogramDeclaration

skipProcedureQualifiers :: ReadP ()
skipProcedureQualifiers = do
  many skipPossibleQualifier
  return ()

skipPossibleQualifier :: ReadP ()
skipPossibleQualifier = do
  _ <- string "pure" <|> string "elemental" <|> string "impure"
  skipAtLeastOneWhiteSpace

skipAtLeastOneWhiteSpace :: ReadP ()
skipAtLeastOneWhiteSpace = do
  _ <- many1 whiteSpace
  return ()

skipSpaceOrEnd :: ReadP ()
skipSpaceOrEnd = eof <|> skipAtLeastOneWhiteSpace

skipSpaceCommaOrEnd :: ReadP ()
skipSpaceCommaOrEnd = eof <|> skipComma <|> skipAtLeastOneWhiteSpace

skipSpaceCommentOrEnd :: ReadP ()
skipSpaceCommentOrEnd = eof <|> skipComment <|> skipAtLeastOneWhiteSpace

skipComma :: ReadP ()
skipComma = do
  _ <- char ','
  return ()

skipComment :: ReadP ()
skipComment = do
  _ <- char '!'
  return ()

skipAnything :: ReadP ()
skipAnything = do
  _ <- many (satisfy (const True))
  return ()

whiteSpace :: ReadP Char
whiteSpace = satisfy (`elem` " \t")

validIdentifier :: ReadP String
validIdentifier = do
  first <- validFirstCharacter
  rest  <- many validIdentifierCharacter
  return $ first : rest

validFirstCharacter :: ReadP Char
validFirstCharacter = alphabet

validIdentifierCharacter :: ReadP Char
validIdentifierCharacter = alphabet <|> digit <|> underscore

alphabet :: ReadP Char
alphabet = satisfy isAsciiLower

digit :: ReadP Char
digit = satisfy isDigit

underscore :: ReadP Char
underscore = char '_'
