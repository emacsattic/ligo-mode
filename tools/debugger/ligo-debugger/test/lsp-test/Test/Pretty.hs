module Test.Pretty
  ( unit_pretty_sum_type_jsligo
  , unit_pretty_sum_type_mligo
  ) where

import Data.Text (strip)
import System.FilePath ((</>))
import Text.Interpolation.Nyan

import Test.Common.Util (renderNoLineLengthLimit)
import Test.Common.Util qualified as Common
import Test.HUnit (Assertion)
import Test.Hspec.Expectations (shouldBe)

import Language.LIGO.AST (SomeLIGO (..), contractTree, lppDialect, parse)
import Language.LIGO.ParseTree (pathToSrc)

contractsDir :: FilePath
contractsDir = Common.contractsDir </> "pretty"

checkPretty :: FilePath -> Text -> Assertion
checkPretty fp expected = do
  contract <- parse =<< pathToSrc (contractsDir </> fp)
  let SomeLIGO lang code = contractTree contract
  strip (renderNoLineLengthLimit $ lppDialect lang code) `shouldBe` expected

unit_pretty_sum_type_jsligo :: Assertion
unit_pretty_sum_type_jsligo = checkPretty "sum-type.jsligo"
  [int||type parameter = ["Increment", int] | ["Decrement", int] | ["Reset"]|]

unit_pretty_sum_type_mligo :: Assertion
unit_pretty_sum_type_mligo = checkPretty "sum-type.mligo"
  [int||type parameter = (Increment of (int) | Decrement of (int) | Reset)|]
