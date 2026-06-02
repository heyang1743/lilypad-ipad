\version "2.24.0"
\language "english"

\header {
  title = "C Major Practice"
  composer = "LilyPad"
  tagline = ##f
}

\score {
  \relative c' {
    \key c \major
    \time 4/4
    c4 d e f | g2 g |
    a4 g f e | d2 c \bar "|."
  }
  \layout { }
  \midi { }
}
