if window?
  require = window.require
  exports = window.exports

blockInfo = require('blockinfo').blockInfo

ChunkSizeY = 256
ChunkSizeZ = 16
ChunkSizeX = 16

cubeCount = 0

class ChunkView
  constructor: (options, @indices, @vertices) -> 
    #if not @indices?
    #  new Int16Array(triangles*3)
    @nbt = options.nbt
    @pos = options.pos
    @unknown = []
    @notexture = []
    @rotcent = true
    @filled = []
    @nomatch = {}
    @ymin = 55
    @superflat = false
    @showStuff = 'diamondsmoss'
    if options.ymin? then @ymin = options.ymin
    #if options.sminx? then @sminx = options.sminx else @sminx = 15
    #@sminz = options.sminz
    #@smaxx = options.smaxx
    #@smaxz = options.smaxz

  
  getBlockAt: (x, y, z) =>
    if not @nbt.root.Level.Sections? then return -1
    sectionnum = Math.floor( (y / 16) )
    offset = ((y%16)*256) + (z * 16) + x
    blockpos = offset

    for section in @nbt.root.Level.Sections
      if section isnt undefined and section.Y * 1 is sectionnum * 1
          
        return section.Blocks[blockpos]
    @nomatch[y] = true    
    return -1

  transNeighbors: (x, y, z) =>
    for i in [x-1..x+1] 
      if i >= ChunkSizeX then continue
      for j in [y-1..y+1] 
        for k in [z-1..z+1]
          if k >= ChunkSizeZ then continue
          if not (i is x and j is y and k is z)
            blockID = @getBlockAt i, j, k
            if blockID is 0 or blockID is -1 or blockID is -10              
              return true

    return false

  extractChunk: =>
    @vertices = []
    @colors = []
    @indices = []
    @textcoords = []
    @filled = []
    @cubeCount = 0

    for x in [0..ChunkSizeX-1]
      for z in [0..ChunkSizeZ-1]
        for y in [@ymin..255]
          id = @getBlockAt x, y, z
          blockType = blockInfo['_'+id]
          if id is 20 then console.log 'foundglass'
          if not blockType?
            if not (id in @unknown) then @unknown.push id 
            id = -1            
          if not blockType?.t?
            if not (id in @notexture) then @notexture.push id
            id = -1
            
          show = false
          show = (id > 0)
          
          if not @superflat and y<60 and @showStuff is 'diamondsmoss'
            show = ( id is 48 or id is 56 or id is 4 or id is 52 )
          else
            if id isnt 0 and id isnt -1 and id isnt -10
              show = @transNeighbors x, y, z
            else
              show = false
          
          if show
            @addBlock [x,y,z]
          else
            blah = 1
           
    @renderPoints()

  addBlock: (position) =>
    verts = [position[0], position[1], position[2]]
    @filled.push verts

  calcPoint: (pos) =>
    verts = []
    if @rotcent
      xmod = 15 * ChunkSizeX
      zmod = 15 * ChunkSizeZ
    else
      xmod = (@sminx + (@smaxx - @sminx) / 2.0) * ChunkSizeX
      zmod = (@sminz + (@smaxz - @sminz) / 2.0) * ChunkSizeZ
    verts.push ((-1 * xmod) + pos[0] + (@pos.x) * ChunkSizeX * 1.00000) 
    verts.push ((pos[1] + 1) * 1.0) 
    verts.push ((-1 * zmod) + pos[2] + (@pos.z) * ChunkSizeZ * 1.00000)
    verts

  renderPoints: =>
    i = 0

    while i < @filled.length
      verts = @filled[i]
      @addTexturedBlock verts
      i++

  getBlockType: (x, y, z) =>
    blockType = blockInfo["_-1"]
    id = @getBlockAt x, y, z
    blockID = "_-1"
    if id? then blockID = "_" + id.toString()  
    if blockInfo[blockID]? then blockType = blockInfo[blockID]  
    blockType

  getBlockInfo: (p) =>
    blockType = blockInfo["_-1"]
    id = @getBlockAt p[0], p[1], p[2]
    blockID = "_-1"
    if id? then blockID = "_" + id.toString()
    if blockInfo[blockID]?
      return blockInfo[blockID]
    else
      return blockInfo["_-1"]

  getColor: (pos) =>
    t = @getBlockType pos[0], pos[1], pos[2]
    t.rgba

  hasNeighbor: (bl, p, offset0, offset1, offset2) =>
    return false
    n = [p[0] + offset0, p[1] + offset1, p[2] + offset2]
    info = @getBlockType(n[0], n[1], n[2])
    #(info.id > 0 and info?.t?) or (info?.t? is 8 or info?.t? is 9)
    if info?.id? is 8 or info?.id? is 9
      return true
    else
      return false

  addTexturedBlock: (p) =>
    a = p
    block = @getBlockInfo(p)
    
    #front face
    @addCubePoint a, -1.0, -1.0, 1.0
    @addCubePoint a, 1.0, -1.0, 1.0
    @addCubePoint a, 1.0, 1.0, 1.0
    @addCubePoint a, -1.0, 1.0, 1.0
    
    #back face
    @addCubePoint a, 1.0, -1.0, -1.0
    @addCubePoint a, -1.0, -1.0, -1.0
    @addCubePoint a, -1.0, 1.0, -1.0
    @addCubePoint a, 1.0, 1.0, -1.0
    
    #top face
    @addCubePoint a, -1.0, 1.0, -1.0
    @addCubePoint a, -1.0, 1.0, 1.0
    @addCubePoint a, 1.0, 1.0, 1.0
    @addCubePoint a, 1.0, 1.0, -1.0
    
    #bottom face
    @addCubePoint a, -1.0, -1.0, -1.0
    @addCubePoint a, 1.0, -1.0, -1.0
    @addCubePoint a, 1.0, -1.0, 1.0
    @addCubePoint a, -1.0, -1.0, 1.0

      
    #4_ _3
    #  |
    #  x
    #  |
    #1_ _2


    #3    2

    #4   1

    #right face
    @addCubePoint a, 1.0, -1.0, 1.0
    @addCubePoint a, 1.0, -1.0, -1.0     
    @addCubePoint a, 1.0, 1.0, -1.0     
    @addCubePoint a, 1.0, 1.0, 1.0
    
    
    #left face    
    @addCubePoint a, -1.0, -1.0, -1.0
    @addCubePoint a, -1.0, -1.0, 1.0
    @addCubePoint a, -1.0, 1.0, 1.0
    @addCubePoint a, -1.0, 1.0, -1.0
    @addFaces @cubeCount * 24, block, p #24
    @cubeCount++

  addCubePoint: (a, xdelta, ydelta, zdelta) =>
    s = xdelta * 0.001
    p2 = [a[0] + xdelta * 0.5 + s, a[1] + ydelta * 0.5 + s, a[2] + zdelta * 0.5 + s]
    p3 = @calcPoint(p2)
    
    @vertices.push p3[0]
    @vertices.push p3[1]
    @vertices.push p3[2]
   

  typeToCoords: (type) =>
    if type.t?
      x = type.t[0]
      y = 15 - type.t[1]
      s = 0.0 # -0.0001
      return [x / 16.0+s, y / 16.0+s, (x + 1.0) / 16.0-s, y / 16.0+s, (x + 1.0) / 16.0-s, (y + 1.0) / 16.0-s, x / 16.0+s, (y + 1.0) / 16.0-s]
    else
      return [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]

  addFaces: (i, bl, p) =>
    coords = @typeToCoords(bl)
    show = {}
    coordsfront = coords
    coordsback = coords
    coordsleft = coords
    coordsright = coords
    coordstop = coords
    coordsbottom = coords

    if bl.id in [37, 38]
      show =
        front: false
        back: false
        top: false
        bottom: false
        left: false
        right: false
    else      
      show.front = not (@hasNeighbor(bl, p, 0, 0, 1))
      show.back = not (@hasNeighbor(bl, p, 0, 0, -1))
      show.top = not (@hasNeighbor(bl, p, 0, 1, 0))
      show.bottom = not (@hasNeighbor(bl, p, 0, -1, 0))
      show.left = not (@hasNeighbor(bl, p, -1, 0, 0))
      show.right = not (@hasNeighbor(bl, p, 1, 0, 0))

    if bl.id is 2
      dirtgrass = blockInfo['_2x']      
      coordsfront = @typeToCoords(dirtgrass)
      coordsback = coordsfront
      coordsleft = coordsfront
      coordsright = coordsfront
      coordsbottom = coordsfront

    totfaces = 0
    totfaces++  if show.front
    totfaces++  if show.back
    totfaces++  if show.top
    totfaces++  if show.bottom
    totfaces++  if show.left
    totfaces++  if show.right

    @indices.push.apply @indices, [i + 0, i + 1, i + 2, i + 0, i + 2, i + 3]  if show.front # Front face
    @indices.push.apply @indices, [i + 4, i + 5, i + 6, i + 4, i + 6, i + 7]  if show.back # Back face
    @indices.push.apply @indices, [i + 8, i + 9, i + 10, i + 8, i + 10, i + 11]  if show.top #,  // Top face
    @indices.push.apply @indices, [i + 12, i + 13, i + 14, i + 12, i + 14, i + 15]  if show.bottom # Bottom face
    @indices.push.apply @indices, [i + 16, i + 17, i + 18, i + 16, i + 18, i + 19]  if show.right # Right face    
    @indices.push.apply @indices, [i + 20, i + 21, i + 22, i + 20, i + 22, i + 23]  if show.left #y/ Left face
    
    
    #if show.front
    @textcoords.push.apply @textcoords, coordsfront
    
    #if show.back
    @textcoords.push.apply @textcoords, coordsback
    
    #if show.top
    @textcoords.push.apply @textcoords, coordstop
    
    #if show.bottom 
    @textcoords.push.apply @textcoords, coordsbottom
    
    #if show.right
    @textcoords.push.apply @textcoords, coordsright
    
    #if show.left
    @textcoords.push.apply @textcoords, coordsleft

    clr = [ bl.rgba[0], bl.rgba[1], bl.rgba[2]]

    @colors.push.apply @colors, clr
    @colors.push.apply @colors, clr
    @colors.push.apply @colors, clr
    @colors.push.apply @colors, clr
    @colors.push.apply @colors, clr
    @colors.push.apply @colors, clr

    @colors.push.apply @colors, clr
    @colors.push.apply @colors, clr
    @colors.push.apply @colors, clr
    @colors.push.apply @colors, clr
    @colors.push.apply @colors, clr
    @colors.push.apply @colors, clr
  
    @colors.push.apply @colors, clr
    @colors.push.apply @colors, clr
    @colors.push.apply @colors, clr
    @colors.push.apply @colors, clr
    @colors.push.apply @colors, clr
    @colors.push.apply @colors, clr
  
    @colors.push.apply @colors, clr
    @colors.push.apply @colors, clr
    @colors.push.apply @colors, clr
    @colors.push.apply @colors, clr
    @colors.push.apply @colors, clr
    @colors.push.apply @colors, clr
 

  
exports.ChunkView = ChunkView

