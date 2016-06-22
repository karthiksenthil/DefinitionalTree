-- ### This program is a stub under development ### --
-- It transforms ICurry into RCurry

import ICurry
import RCurry

execute (IModule name imported_list data_list funct_list)
  = let constr_list = concatMap single_data data_list
        fun_declar_list = map single_funct_declare funct_list
        fun_defin_list = map single_funct_def funct_list
    in RModule name imported_list constr_list fun_declar_list fun_defin_list

single_data (_, constr_list)
  = map single_constr (zip constr_list [4..])

single_constr ((IConstructor qname arity), index)
  = RConstructor qname arity index

single_funct_declare (IFunction qname arity _)
        = RFunctionDeclaration qname arity

single_funct_def (IFunction qname arity stmt_list)
  = RFunctionDefinition qname arity (map single_stmt stmt_list)

--------------------------------------------------------------

single_stmt (Declare (Variable identifier (ILhs (n, i))))
        = RVariable (RILhs identifier i)

single_stmt (Declare (Variable identifier (IVar j (_,i))))
        = RVariable (RIVar identifier j i)
  
single_stmt (Declare (Variable identifier ICase))
  = RVariable (RICase identifier)

single_stmt (Declare (Variable identifier IBind))
  = RVariable (RIBind identifier)

single_stmt (Declare (Variable identifier IFree))
  = RVariable (RIFree identifier)

single_stmt (Assign i expr)
  = RAssign i (single_expr expr)

-- branch_list is [(IConstructor,[Statement])]
-- the constructors are in order 4, 5, 6, ...
-- strip them away and convert the statements

single_stmt (ATable _ _ expr branch_list)
  = let constr_branch_list 
          = [(name, map single_stmt bl) | 
	       (IConstructor (_,name) _, bl) <- branch_list]
        all_branch_list
	  = zip [0..] (default_branches expr ++ constr_branch_list)
    in RATable (single_expr expr) all_branch_list


-- if expr is constructor rooted, then return it;
-- otherwise, recursively invoke the H function on it.
single_stmt (Return expr)
  = RReturn mode (single_expr expr)
  where mode = case expr of
                 Exempt -> Done
                 Reference _ -> Check
                 BuiltinVariant _ -> Done
                 Applic True _ _ -> Done
                 Applic False _ _ -> Recur
                 PartApplic _ _ -> Done
                 IOr _ _ -> Recur

single_stmt (IExternal qname) = RExternal qname

single_stmt (Comment string) = RComment string
single_stmt (Fill i list j) = RFill i (map snd list) j
single_stmt (BTable _ _ _ _) = RBTable

--------------------------------------------------------------

single_expr (Reference i) = Ref i

single_expr (Applic bool qname arg_list)
  | qname == ("Prelude","?")
  = single_expr (IOr (head arg_list) (head (tail arg_list)))
  | otherwise
  = Application bool qname (map single_expr arg_list)

single_expr (IOr expr_1 expr_2)
  = ROr (single_expr expr_1) (single_expr expr_2)

single_expr (BuiltinVariant (Bint num))
  = Integer num  

single_expr (BuiltinVariant (Bchar ch))
  = Character ch

single_expr (PartApplic miss expr) = RPartial miss (single_expr expr)

single_expr Exempt = FailExpression

--------------------------------------------------------------

single_branch ((IConstructor (mod,name) _), stmt_list)
  = let case_stmts = map single_stmt stmt_list
    in (mod++"."++name, case_stmts) 

-- TODO: replace Prelude.failed with something more abstract

-- These are the 4 initial entries in a pattern matching case
-- They correspond to the following matches of the inductive variable
--   0 => a free variable
--   1 => a choice-rooted expression
--   2 => the fail expression
--   3 => an operation-rooted expression
-- Each entry is a list of RCurry statements

default_branches expr
  = [ ("VARIABLE",
       [RException "Handling Variables not implemented yet"])
    , ("CHOICE", [RHFunction (single_expr expr), RHFunction (Expr "expr")])
    , ("FAIL", [RReturn Done FailExpression])
    , ("OPERATION", [RHFunction (single_expr expr), RHFunction (Expr "expr")])
    ]
