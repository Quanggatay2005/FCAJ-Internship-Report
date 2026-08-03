function Header(el)
  return pandoc.RawBlock('latex', '\\vspace{0.5em}\\noindent\\textbf{' .. pandoc.utils.stringify(el.content) .. '}\\par')
end
