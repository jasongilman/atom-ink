{CompositeDisposable} = require 'atom'

module.exports =
class EditorOverlay
  fadeIn: ->
    @view.classList.add 'ink-hide'
    @timeout 20, =>
      @view.classList.remove 'ink-hide'

  lineRange: (start, end) ->
    [[start, 0], [end, @editor.lineTextForBufferRow(end).length]]

  remove: ->
    @view.classList.add 'ink-hide'
    @timeout 200, => @destroy()

  destroy: ->
    @marker.destroy()
    @disposables.dispose()

  invalidate: ->
    @view.classList.add 'invalid'
    @invalid = true

  validate: ->
    @view.classList.remove 'invalid'
    @invalid = false

  checkMarker: (e) ->
    if !e.isValid or @marker.getBufferRange().isEmpty()
      @remove()
    else if e.textChanged
      old = e.oldHeadScreenPosition
      nu = e.newHeadScreenPosition
      if old.isLessThan nu
        text = @editor.getTextInRange([old, nu])
        if text.match /^\r?\n\s*$/
          @marker.setHeadBufferPosition old

  validateText: ->
    text = @getText()
    if @text == text and @invalid then @validate()
    else if @text != text and !@invalid then @invalidate()

  timeout: (t, f) -> setTimeout f, t

  getText: ->
    @editor.getTextInRange(@marker.getBufferRange()).trim()


  # Bulk Actions

  @all: -> # TODO: scope selector
    results = []
    for item in atom.workspace.getPaneItems() when atom.workspace.isTextEditor item
      item.findMarkers().filter((m) -> m.result?).forEach (m) ->
        results.push m.result
    results

  @invalidateAll: ->
    for result in @all()
      delete result.text
      result.invalidate()

  @forLines: (ed, start, end, kind = 'any') ->
    ed.findMarkers().filter((m) -> m.result? &&
                                   m.getBufferRange().intersectsRowRange(start, end) &&
                                  (m.result.kind == kind || kind == 'any'))
                    .map((m) -> m.result)

  @removeLines: (ed, start, end, kind = 'any') ->
    rs = @forLines(ed, start, end, kind)
    rs.map (r) -> r.remove()
    rs.length > 0

  @removeAll: (ed = atom.workspace.getActiveTextEditor()) ->
    ed?.findMarkers().filter((m) -> m.result?).map((m) -> m.result.remove())

  @removeCurrent: (e) ->
    if (ed = atom.workspace.getActiveTextEditor())
      for sel in ed.getSelections()
        if @removeLines(ed, sel.getHeadBufferPosition().row, sel.getTailBufferPosition().row)
          done = true
    e.abortKeyBinding() unless done
