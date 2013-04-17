-- file: ch05/Prettify.hs
punctuate :: Doc -> [Doc] -> [Doc]
punctuate p []     = []
punctuate p [d]    = [d]
punctuate p (d:ds) = (d <> p) : punctuate p ds

-- file: ch05/Prettify.hs
data Doc = Empty
         | Char Char
         | Text String
         | Line
         | Concat Doc Doc
         | Union Doc Doc
           deriving (Show,Eq)

-- file: ch05/Prettify.hs
empty :: Doc
empty = Empty

char :: Char -> Doc
char c = Char c

text :: String -> Doc
text "" = Empty
text s  = Text s

double :: Double -> Doc
double d = text (show d)

-- file: ch05/Prettify.hs
line :: Doc
line = Line

-- file: ch05/Prettify.hs
(<>) :: Doc -> Doc -> Doc
Empty <> y = y
x <> Empty = x
x <> y = x `Concat` y

-- file: ch05/Prettify.hs
hcat :: [Doc] -> Doc
hcat = fold (<>)

fold :: (Doc -> Doc -> Doc) -> [Doc] -> Doc
fold f = foldr f empty

-- file: ch05/Prettify.hs
fsep :: [Doc] -> Doc
fsep = fold (</>)

(</>) :: Doc -> Doc -> Doc
x </> y = x <> softline <> y

softline :: Doc
softline = group line

-- file: ch05/Prettify.hs
group :: Doc -> Doc
group x = flatten x `Union` x

-- file: ch05/Prettify.hs
flatten :: Doc -> Doc
flatten (x `Concat` y) = flatten x `Concat` flatten y
flatten Line           = Char ' '
flatten (x `Union` _)  = flatten x
flatten other          = other

-- file: ch05/Prettify.hs
compact :: Doc -> String
compact x = transform [x]
    where transform [] = ""
          transform (d:ds) =
              case d of
                Empty        -> transform ds
                Char c       -> c : transform ds
                Text s       -> s ++ transform ds
                Line         -> '\n' : transform ds
                a `Concat` b -> transform (a:b:ds)
                _ `Union` b  -> transform (b:ds)

-- file: ch05/Prettify.hs
pretty :: Int -> Doc -> String

-- file: ch05/Prettify.hs
pretty width x = best 0 [x]
    where best col (d:ds) =
              case d of
                Empty        -> best col ds
                Char c       -> c :  best (col + 1) ds
                Text s       -> s ++ best (col + length s) ds
                Line         -> '\n' : best 0 ds
                a `Concat` b -> best col (a:b:ds)
                a `Union` b  -> nicest col (best col (a:ds))
                                           (best col (b:ds))
          best _ _ = ""

          nicest col a b | (width - least) `fits` a = a
                         | otherwise                = b
                         where least = min width col

-- file: ch05/Prettify.hs
fits :: Int -> String -> Bool
w `fits` _ | w < 0 = False
w `fits` ""        = True
w `fits` ('\n':_)  = True
w `fits` (c:cs)    = (w - 1) `fits` cs

-- Char c needed on the right side of '->' for it is looking for a Doc -> Doc type
-- Same with Text s, not just 'c' or 's'.

fill :: Int -> Doc -> Doc
fill width x = node 0 [x]
    where node col (d:ds) = 
            case d of
                Empty             -> Empty <> node col ds
                Char c            -> Char c <> node (col+1) ds                                -- Can also use Concat (Char c) (node (col+1) ds)
                Text s            -> Text s <> node (col+length s) ds
                Line              -> Line <> node 0 ds
                a `Concat` b      -> node col (a:b:ds)
                a `Union` b       -> (node col (a:ds)) `Union` (node col (b:ds))
    
          node col [] = Text (replicate (width - col) ' ')
 
nest :: Int -> Doc -> Doc         
nest width x = node 0 x
    where node amt d = 
            case d of 
                Empty               -> Empty <> node amt d
                Char c              -> Char c <> node (amt+1) d
                Text s              -> Text s <> node (amt+length s) d
                Line                -> Line <> node 0 d
                a `Concat` b        -> (node amt a) `Concat` (node amt b)
                a `Union` b         -> (node amt a) `Union` (node amt b)
                Char '[' `Concat` d -> Char '[' `Concat` node (amt+1) d
                Char '{' `Concat` d -> Char '{' `Concat` node (amt+1) d
                
          node amt _ = Text (replicate (width - amt) ' ')
