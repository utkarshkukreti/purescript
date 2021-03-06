-----------------------------------------------------------------------------
--
-- Module      :  Language.PureScript.Declarations
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

{-# LANGUAGE DeriveDataTypeable #-}

module Language.PureScript.Declarations where

import Language.PureScript.Values
import Language.PureScript.Types
import Language.PureScript.Names
import Language.PureScript.Kinds
import Language.PureScript.CodeGen.JS.AST

import qualified Data.Data as D

type Precedence = Integer

data Associativity = Infixl | Infixr deriving (Show, D.Data, D.Typeable)

data Fixity = Fixity Associativity Precedence deriving (Show, D.Data, D.Typeable)

data Module = Module ProperName [Declaration] deriving (Show, D.Data, D.Typeable)

data Declaration
  = DataDeclaration ProperName [String] [(ProperName, Maybe Type)]
  | DataBindingGroupDeclaration [(ProperName, [String], [(ProperName, Maybe Type)])]
  | TypeSynonymDeclaration ProperName [String] Type
  | TypeDeclaration Ident Type
  | ValueDeclaration Ident [[Binder]] (Maybe Guard) Value
  | BindingGroupDeclaration [(Ident, Value)]
  | ExternDeclaration Ident (Maybe JS) Type
  | ExternDataDeclaration ProperName Kind
  | FixityDeclaration Fixity String
  | ImportDeclaration ModuleName (Maybe [Either Ident ProperName])
  deriving (Show, D.Data, D.Typeable)
