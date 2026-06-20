-- Deletes <img src="image.svg"> and Markdown images ![](file.svg)
function Image (img)
  if img.src:match("%.svg") or img.src:sub(1, 14) == 'data:image/svg' then
    return {}
  end
end