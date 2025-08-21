-- filters/replace-mathbb-to-mathds.lua
-- Replace \mathbb 1 (and \mathbb{1}, \mathbb1) with \mathds 1 for PDF/LaTeX outputs only.

local function is_pdf()
  if quarto and quarto.doc and quarto.doc.is_format then
    return quarto.doc.is_format("pdf") or quarto.doc.is_format("beamer")
  end
  if FORMAT then
    return FORMAT:match("latex") or FORMAT:match("pdf")
  end
  return false
end

return {
  Math = function(m)
    if not is_pdf() then return nil end
    local s = m.text
    -- handle braced form first
    local s1, n1 = s:gsub("\\mathbb%s*%{1%}", "\\mathds{1}")
    -- handle spaced form
    local s2, n2 = s1:gsub("\\mathbb%s+1", "\\mathds 1")
    -- handle no-space form
    local s3, n3 = s2:gsub("\\mathbb1", "\\mathds 1")
    if (n1 + n2 + n3) > 0 then
      return pandoc.Math(m.mathtype, s3)
    end
  end
}