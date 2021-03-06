-----------------------------------------------------------------------------
--
-- Module      :  Language.PureScript.Pretty.Types
-- Copyright   :  (c) Phil Freeman 2013
-- License     :  MIT
--
-- Maintainer  :  Phil Freeman <paf31@cantab.net>
-- Stability   :  experimental
-- Portability :
--
-- |
--
-----------------------------------------------------------------------------

module Language.PureScript.Pretty.Types (
    prettyPrintType,
    prettyPrintRow
) where

import Data.Maybe (fromMaybe)
import Data.List (intercalate)
import Control.Arrow ((<+>))

import Language.PureScript.Types
import Language.PureScript.Pretty.Common
import Language.PureScript.Unknown

typeLiterals :: Pattern () Type String
typeLiterals = mkPattern match
  where
  match Number = Just "Number"
  match String = Just "String"
  match Boolean = Just "Boolean"
  match (Array ty) = Just $ "[" ++ prettyPrintType ty ++ "]"
  match (Object row) = Just $ "{ " ++ prettyPrintType row ++ " }"
  match (TypeVar var) = Just var
  match (TypeConstructor ctor) = Just $ show ctor
  match (TUnknown (Unknown u)) = Just $ 'u' : show u
  match (Skolem s) = Just $ 's' : show s
  match (SaturatedTypeSynonym name args) = Just $ show name ++ "<" ++ intercalate "," (map prettyPrintType args) ++ ">"
  match (ForAll ident ty) = Just $ "forall " ++ ident ++ ". " ++ prettyPrintType ty
  match REmpty = Just $ prettyPrintRow REmpty
  match row@(RCons _ _ _) = Just $ prettyPrintRow row
  match _ = Nothing

prettyPrintRow :: Type -> String
prettyPrintRow = (\(tys, rest) -> intercalate ", " (map (uncurry nameAndTypeToPs) tys) ++ tailToPs rest) . toList []
  where
  nameAndTypeToPs :: String -> Type -> String
  nameAndTypeToPs name ty = name ++ " :: " ++ prettyPrintType ty
  tailToPs :: Type -> String
  tailToPs REmpty = ""
  tailToPs (TUnknown (Unknown u)) = " | u" ++ show u
  tailToPs (TypeVar var) = " | " ++ var
  tailToPs (Skolem s) = " | s" ++ show s
  tailToPs _ = error "Invalid row tail"
  toList :: [(String, Type)] -> Type -> ([(String, Type)], Type)
  toList tys (RCons name ty row) = toList ((name, ty):tys) row
  toList tys r = (tys, r)

typeApp :: Pattern () Type (Type, Type)
typeApp = mkPattern match
  where
  match (TypeApp f x) = Just (f, x)
  match _ = Nothing

singleArgumentFunction :: Pattern () Type (Type, Type)
singleArgumentFunction = mkPattern match
  where
  match (Function [arg] ret) = Just (arg, ret)
  match _ = Nothing

function :: Pattern () Type ([Type], Type)
function = mkPattern match
  where
  match (Function args ret) = Just (args, ret)
  match _ = Nothing

prettyPrintType :: Type -> String
prettyPrintType = fromMaybe (error "Incomplete pattern") . pattern matchType ()
  where
  matchType :: Pattern () Type String
  matchType = buildPrettyPrinter operators (typeLiterals <+> fmap parens matchType)
  operators :: OperatorTable () Type String
  operators =
    OperatorTable [ [ AssocL typeApp $ \f x -> f ++ " " ++ x ]
                  , [ AssocR singleArgumentFunction $ \arg ret -> arg ++ " -> " ++ ret
                    , Wrap function $ \args ret -> "(" ++ intercalate ", " (map prettyPrintType args) ++ ") -> " ++ ret
                    ]
                  ]
