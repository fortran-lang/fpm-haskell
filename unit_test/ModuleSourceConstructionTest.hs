module ModuleSourceConstructionTest
  ( test
  )
where

import           BuildModel                     ( RawSource(..)
                                                , Source(..)
                                                , processRawSource
                                                )
import           Hedge                          ( Result
                                                , Test
                                                , assertEquals
                                                , assertThat
                                                , fail'
                                                , givenInput
                                                , then'
                                                , whenTransformed
                                                )
import           System.FilePath                ( (</>) )

test :: IO (Test ())
test = return $ givenInput
  "a module"
  exampleModule
  [ whenTransformed
      "processed to a source"
      processRawSource
      [ then' "it is a Module" checkIsModule
      , then' "its source file name is the same as the original"
              checkModuleSourceFileName
      , then'
        "its object file name is the 'flattened' path of the source file with '.o' appeneded"
        checkModuleObjectFileName
      , then' "it knows what modules it uses directly" checkModuleModulesUsed
      , then' "it knows its name"                      checkModuleName
      , then' "it can tell that it will produce a '.smod' file" checkSmod
      ]
  ]

exampleModule :: RawSource
exampleModule = RawSource moduleSourceFileName' $ unlines
  [ "module some_module"
  , "  use module1"
  , "  USE MODULE2"
  , "  implicit none"
  , "  interface"
  , "    pure module function some_func()"
  , "      integer :: some_func"
  , "    end function"
  , "  end interface"
  , "end module"
  ]

moduleSourceFileName' :: String
moduleSourceFileName' = "some" </> "file" </> "somewhere.f90"

checkIsModule :: Source -> Result
checkIsModule Module{} = assertThat True
checkIsModule _        = assertThat False

checkModuleSourceFileName :: Source -> Result
checkModuleSourceFileName m@(Module{}) =
  assertEquals moduleSourceFileName' $ moduleSourceFileName m
checkModuleSourceFileName _ = fail' "wasn't a Module"

checkModuleObjectFileName :: Source -> Result
checkModuleObjectFileName m@(Module{}) =
  assertEquals ("." </> "some_file_somewhere.f90.o")
    $ (moduleObjectFileName m) "."
checkModuleObjectFileName _ = fail' "wasn't a Module"

checkModuleModulesUsed :: Source -> Result
checkModuleModulesUsed m@(Module{}) =
  assertEquals ["module1", "module2"] $ moduleModulesUsed m
checkModuleModulesUsed _ = fail' "wasn't a Module"

checkModuleName :: Source -> Result
checkModuleName m@(Module{}) = assertEquals "some_module" $ moduleName m
checkModuleName _            = fail' "wasn't a Module"

checkSmod :: Source -> Result
checkSmod m@(Module{}) = assertThat $ moduleProducesSmod m
checkSmod _ = fail' "wasn't a Module"
