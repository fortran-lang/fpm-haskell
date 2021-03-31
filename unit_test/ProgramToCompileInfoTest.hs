module ProgramToCompileInfoTest
  ( test
  )
where

import           BuildModel                     ( AvailableModule(..)
                                                , CompileTimeInfo(..)
                                                , Source(..)
                                                , constructCompileTimeInfo
                                                )
import           Hedge                          ( Result
                                                , Test
                                                , assertEmpty
                                                , assertEquals
                                                , givenInput
                                                , then'
                                                , whenTransformed
                                                )
import           System.FilePath                ( (</>) )

test :: IO (Test ())
test = return $ givenInput
  "a program and available modules"
  (exampleProgram, availableModules)
  [ whenTransformed
      "its compileTimeInfo is determined"
      doCompileTimeTransformation
      [ then' "it still knows the original source file"    checkSourceFileName
      , then' "it knows what object file will be produced" checkObjectFileName
      , then' "there are no other files produced" checkOtherFilesProduced
      , then' "the direct dependencies are only the available modules used"
              checkDirectDependencies
      ]
  ]

exampleProgram :: Source
exampleProgram = Program
  { programSourceFileName = programSourceFileName'
  , programObjectFileName = \bd -> bd </> "some_file_somewhere.f90.o"
  , programModulesUsed    = ["module1", "module2", "module3"]
  }

programSourceFileName' :: FilePath
programSourceFileName' = "some" </> "file" </> "somewhere.f90"

availableModules :: [AvailableModule]
availableModules = [ AvailableModule {availableModuleName = "module1", availableModuleFile = "build_dir" </> "module1.mod"}
                   , AvailableModule {availableModuleName = "module3", availableModuleFile = "build_dir" </> "module3.mod"}
                   ]

doCompileTimeTransformation :: (Source, [AvailableModule]) -> CompileTimeInfo
doCompileTimeTransformation (programSource, otherSources) =
  constructCompileTimeInfo programSource otherSources "build_dir"

checkSourceFileName :: CompileTimeInfo -> Result
checkSourceFileName cti =
  assertEquals programSourceFileName' (compileTimeInfoSourceFileName cti)

checkObjectFileName :: CompileTimeInfo -> Result
checkObjectFileName cti = assertEquals
  ("build_dir" </> "some_file_somewhere.f90.o")
  (compileTimeInfoObjectFileProduced cti)

checkOtherFilesProduced :: CompileTimeInfo -> Result
checkOtherFilesProduced cti =
  assertEmpty (compileTimeInfoOtherFilesProduced cti)

checkDirectDependencies :: CompileTimeInfo -> Result
checkDirectDependencies cti = assertEquals
  ["build_dir" </> "module1.mod", "build_dir" </> "module3.mod"]
  (compileTimeInfoDirectDependencies cti)
