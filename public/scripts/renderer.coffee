if window?
  require = window.require
  exports = window.exports

SCALE = 5

chunks = require 'chunk'
ChunkView = require('chunkview').ChunkView
blockInfo = require('blockinfo').blockInfo

delay = (ms, func) ->
  setTimeout func, ms

class RegionRenderer
  constructor: (@region) ->          
    @mouseX = 0
    @mouseY = 0

    @windowHalfX = window.innerWidth / 2;
    @windowHalfY = window.innerHeight / 2;

    @init()
    @animate()
    @load()

  #I need to put the camera at a certain x,y,z
  #so I need to calculate which chunk it is in
  #and what block within that chunk
  #then I need to 
  #use the equation from calcPoint
  #to get the position and add it to the
  #mesh position
  #which chunk x z is it?
  #32x32 chunks
  mcCoordsToWorld: (x, y, z) =>
    chunkX = x % 32
    chunkZ = z % 32
    posX = x % (32 * 16)
    posZ = x % (32 * 16)
    posY = y
    xmod = 15 * 16
    zmod = 15 * 16
    ret = new THREE.Vector3()
    ret.x = ((-1 * xmod) + posX + (chunkX) * 16 * 1.00000) 
    ret.y = ((posY + 1) * 1.0) 
    ret.z = ((-1 * zmod) + posZ + (chunkZ) * 16 * 1.00000) 
    ret.x += 700
    ret.z += 700
    return ret

  loadChunk: (chunk, chunkX, chunkZ) =>
    options =
      nbt: chunk
      pos:
        x: chunkX
        z: chunkZ
    view = new ChunkView(options)    
    view.extractChunk()
    triangles = view.indices.length / 3
    vertexIndexArray = new Uint16Array(view.indices.length)
    for i in [0...view.indices.length]
      vertexIndexArray[i] = view.indices[i]

    vertexPositionArray = new Float32Array(view.vertices.length)
    for i in [0...view.vertices.length]
      vertexPositionArray[i] = view.vertices[i]

    uvArray = new Float32Array(view.textcoords.length)
    for i in [0...view.textcoords.length]
      uvArray[i] = view.textcoords[i]

    attributes =
      index:
        itemSize: 1
        array: vertexIndexArray
        numItems: vertexIndexArray.length 
      position:
        itemSize: 3
        array: vertexPositionArray
        numItems: vertexPositionArray.length / 3
      uv:
        itemSize: 2
        array: uvArray
        numItems: uvArray.length / 2

    geometry = new THREE.BufferGeometry()
    geometry.attributes = attributes
        
    geometry.offsets = [{
      start: 0
      count: vertexIndexArray.length
      index: 0
    }]
      
    geometry.computeBoundingBox()
    geometry.computeBoundingSphere()
    geometry.computeVertexNormals()

    material = @loadTexture('/terrain.png')
    mesh = new THREE.Mesh(geometry, material)
    mesh.position.x = 700.0
    mesh.position.y = 0.0
    mesh.position.z = 700.0
    mesh.doubleSided = true
    @scene.add mesh

    centerX = mesh.position.x + 0.5 * ( geometry.boundingBox.max.x - geometry.boundingBox.min.x )
    centerY = mesh.position.y + 0.5 * ( geometry.boundingBox.max.y - geometry.boundingBox.min.y )
    centerZ = mesh.position.z + 0.5 * ( geometry.boundingBox.max.z - geometry.boundingBox.min.z )
    @camera.lookAt mesh.position
    return null

  loadTexture: (path) =>
    image = new Image()
    image.onload = -> texture.needsUpdate = true
    image.src = path
    texture  = new THREE.Texture( image,  new THREE.UVMapping(), THREE.ClampToEdgeWrapping , THREE.ClampToEdgeWrapping , THREE.NearestFilter, THREE.NearestFilter )    

    return new THREE.MeshLambertMaterial( { map: texture, transparent: true } )

  load: =>
    @colors = []    
    @geometry = new THREE.Geometry()
    @geometry.colors = @colors
    @material = new THREE.ParticleBasicMaterial( { size: 5, vertexColors: true } )
    @material.color.setHSV 200, 200, 200
    particles = new THREE.ParticleSystem( @geometry, @material )
    particles.rotation.x = 0
    particles.rotation.y = Math.random() * 6
    particles.rotation.z = 0
    camPos = @mcCoordsToWorld(0,70,0)
    console.log 'camPos'
    console.log camPos
    @camera.position.x = camPos.x
    @camera.position.y = camPos.y
    @camera.position.z = camPos.z
    #@scene.add particles
    start = new Date().getTime()
    for x in [0..10]
      for z in [0..10]
        region = @region
        if true or @region.hasChunk x,z
          try
            chunk = region.getChunk x,z
            if chunk?
              @loadChunk chunk, x, z
          catch e
            console.log e.message
            console.log e.stack

    total = new Date().getTime() - start
    seconds = total / 1000.0
    console.log "processed chunks into #{@geometry.vertices.length} vertices in #{seconds} seconds"


  showProgress: (ratio) =>
    $('#proginner').width 300*ratio

  init: =>
    container = document.createElement 'div'
    document.body.appendChild container 

    @clock = new THREE.Clock()

    @camera = new THREE.PerspectiveCamera( 60, window.innerWidth / window.innerHeight, 1, 2300 )
    @camera.position.z = 50
    @camera.position.y = 25
    
    @scene = new THREE.Scene()

    @scene.add new THREE.AmbientLight(0x888888)
    directionalLight = new THREE.DirectionalLight( 0xcccccc )
    directionalLight.position.set( 9, 30, 300 )
 
    @scene.add directionalLight

    #@pointLight = new THREE.PointLight(0xddcccc, 1, 500)
    #@pointLight.position.set(0,0,0)
    #@scene.add @pointLight

    @renderer = new THREE.WebGLRenderer({  antialias	: true })
 
    #@renderer.setClearColorHex( 0x000000, 1 )
    @renderer.setSize window.innerWidth, window.innerHeight
    container.appendChild @renderer.domElement

    @controls = new THREE.FirstPersonControls( @camera )
    @controls.movementSpeed = 20
    @controls.lookSpeed = 0.125
    @controls.lookVertical = true

    @stats = new Stats()
    @stats.domElement.style.position = 'absolute'
    @stats.domElement.style.top = '0px'
    container.appendChild @stats.domElement

    window.addEventListener 'resize', @onWindowResize, false

  onWindowResize: =>
    @windowHalfX = window.innerWidth / 2
    @windowHalfY = window.innerHeight / 2

    @camera.aspect = window.innerWidth / window.innerHeight
    @camera.updateProjectionMatrix()
  
    @controls.handleResize()

    @renderer.setSize window.innerWidth, window.innerHeight

  animate: =>
    requestAnimationFrame @animate
    @render()
    @stats.update()

  render: =>
    time = Date.now() * 0.00005
    @controls.update @clock.getDelta()
    #@pointLight.position.set @camera.position.x, @camera.position.y, @camera.position.z
    #@camera.lookAt @scene.position
    #for i in [0..@scene.children.length-1]
    ##  object = @scene.children[ i ]
    #  if object instanceof THREE.ParticleSystem
    #    object.rotation.y = time * ( i < 4 ? i + 1 : - ( i + 1 ) )
    @renderer.render @scene, @camera


exports.RegionRenderer = RegionRenderer

