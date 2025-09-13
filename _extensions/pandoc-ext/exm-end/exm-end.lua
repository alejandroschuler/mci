-- exm-wrap.lua — turn .MyExample into a numbered Example, add two newlines after,
-- and remap ids @myexm-* -> @exm-* so crossrefs work.

local map = {}   -- myexm-* -> exm-*
local matched = 0

local function is_pdf()
  return (quarto and quarto.doc and (quarto.doc.is_format("pdf") or quarto.doc.is_format("beamer")))
      or (FORMAT and (FORMAT:match("latex") or FORMAT:match("pdf")))
end

local function has_class(el, want)
  if not el.classes then return false end
  for _,c in ipairs(el.classes) do if c == want then return true end end
  return false
end

local function ensure_example_classes(el)
  el.classes = el.classes or {}
  local have = {}
  for _,c in ipairs(el.classes) do have[c] = true end
  if not have["theorem"] then table.insert(el.classes, "theorem") end
  if not have["example"] then table.insert(el.classes, "example") end
end

-- Two "newlines" after the example
local function marker_block()
  if is_pdf() then
    -- Two paragraph breaks in LaTeX
    -- return pandoc.RawBlock("latex", "\\par\\par")
    -- If you prefer fixed vertical space instead, use:
    return pandoc.RawBlock("latex", "\\vspace{0.75\\baselineskip}")
  else
    -- Two line breaks in HTML
    return pandoc.RawBlock("html", "<br/>")
  end
end

-- Normalize id: if starts with myexm-, convert to exm- and remember mapping
local function normalize_id(el)
  local id = el.identifier or (el.attr and el.attr.identifier) or ""
  if id:match("^myexm%-") then
    local new = id:gsub("^myexm%-", "exm-")
    map["@"..id] = "@"..new
    el.identifier = new
    if el.attr then el.attr.identifier = new end
  end
end

-- Rewrite inline @myexm-* to @exm-* (covers crossref tokens and # links)
local function rewriter_for_inlines(inl)
  if inl.t == "Str" then
    local txt = inl.text
    for k,v in pairs(map) do
      if txt:find(k, 1, true) then
        inl.text = txt:gsub(k, v)
        return inl
      end
    end
  elseif inl.t == "Link" and inl.target and inl.target:match("^#myexm%-") then
    inl.target = inl.target:gsub("^#myexm%-", "#exm-")
    return inl
  end
  return nil
end

return {
  -- Convert .MyExample/.myexample to real Examples, normalize id, and append spacing
  Div = function(el)
    if has_class(el, "Exm") or has_class(el, "exm") then
      matched = matched + 1
      ensure_example_classes(el)
      normalize_id(el)
      table.insert(el.content, marker_block())
      return el
    end
    return nil
  end,

  -- Rewrite cross-refs if any were remapped
  Inlines = function(inlines)
    if next(map) == nil then return nil end
    return inlines:walk { Str = rewriter_for_inlines, Link = rewriter_for_inlines }
  end,

  Pandoc = function(doc)
    if quarto and quarto.log then
      local n=0 for _ in pairs(map) do n=n+1 end
    --   quarto.log.output(string.format("[exm-wrap] converted %d MyExample blocks; remapped %d ids", matched, n))
    end
    return doc
  end
}