import           Development.Shake.FilePath     ( (</>) )
import           Fpm                            ( Arguments(..)
                                                , start
                                                )
import           System.Directory               ( withCurrentDirectory )

example_path = "test" </> "example_packages"

main :: IO ()
main = do
  testHelloWorld
  testHelloComplex
  testHelloFpm
  testCircular
  testWithMakefile
  testMakefileComplex
  testSubmodule

testHelloWorld :: IO ()
testHelloWorld =
  withCurrentDirectory (example_path </> "hello_world") $ start $ Run
    { runRelease = False
    , runExample = False
    , runCompiler = "gfortran"
    , runFlags = []
    , runRunner = Nothing
    , runTarget  = Nothing
    , runArgs    = Nothing
    }

testHelloComplex :: IO ()
testHelloComplex =
  withCurrentDirectory (example_path </> "hello_complex") $ start $ Test
    { testRelease = False
    , testCompiler = "gfortran"
    , testFlags = []
    , testRunner = Nothing
    , testTarget  = Nothing
    , testArgs    = Nothing
    }

testHelloFpm :: IO ()
testHelloFpm =
  withCurrentDirectory (example_path </> "hello_fpm") $ start $ Run
    { runRelease = False
    , runExample = False
    , runCompiler = "gfortran"
    , runFlags = []
    , runRunner = Nothing
    , runTarget  = Nothing
    , runArgs    = Nothing
    }

testWithExamples :: IO ()
testWithExamples =
  withCurrentDirectory (example_path </> "with_examples") $ start $ Run
    { runRelease = False
    , runExample = True
    , runCompiler = "gfortran"
    , runFlags = []
    , runRunner = Nothing
    , runTarget  = Nothing
    , runArgs    = Nothing
    }

testCircular :: IO ()
testCircular =
  withCurrentDirectory (example_path </> "circular_example") $ start $ Test
    { testRelease = False
    , testCompiler = "gfortran"
    , testFlags = []
    , testRunner = Nothing
    , testTarget  = Nothing
    , testArgs    = Nothing
    }

testWithMakefile :: IO ()
testWithMakefile =
  withCurrentDirectory (example_path </> "with_makefile") $ start $ Build
    { buildRelease = False
    , buildCompiler = "gfortran"
    , buildFlags = []
    }

testMakefileComplex :: IO ()
testMakefileComplex =
  withCurrentDirectory (example_path </> "makefile_complex") $ start $ Run
    { runRelease = False
    , runExample = False
    , runCompiler = "gfortran"
    , runFlags = []
    , runRunner = Nothing
    , runTarget  = Nothing
    , runArgs    = Nothing
    }

testSubmodule :: IO ()
testSubmodule =
  withCurrentDirectory (example_path </> "submodules") $ start $ Build
    { buildRelease = False
    , buildCompiler = "gfortran"
    , buildFlags = []
    }
