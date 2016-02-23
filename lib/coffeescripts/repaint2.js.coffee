class glob.Repaint extends RT.Stratum

  constructor: ->
    super
    @addManager 'itemsManager', new ItemsManager
    document.body.append @div id: 'app', ->
      @list()

class ItemsManager extends RT.BaseManager

  STORAGE_NAME = 'todos-redtea'

  constructor: ->

  render: ->
    databases = ENV.generateData().toArray()
    if @storageItems.count() == 0
      for db in databases
        @storageItems.push new RT.StorageItem db
    else
      for item, i in @storageItems.items
        db = databases[i]
        item.get('dbnames').first().set 'dbname', db.dbname
        t = item.get('queryCount').first()
        t.set 'countClassName', db.lastSample.countClassName
        t.set 'nbQueries', db.lastSample.nbQueries
        for q, j in db.lastSample.topFiveQueries
          tt = item.get('topQuery').items[j]
          tt.set 'elapsedClassName', q.elapsedClassName
          tt.set 'formatElapsed', q.formatElapsed
          tt.set 'query', q.query

    Monitoring.renderRate.ping()
    setTimeout =>
      @render()
    , ENV.timeout

  setStorageItems: (@storageItems)->
    @render()

#========== Виджеты ==========
#-----------------------------
class List extends RT.Widget

  @register 'list'

  managers: ['itemsManager']

  itemsManagerLoaded: ->
    @itemsManager.setStorageItems @getCollectionField('items')

  #DOM-структура виджета ====================-
  createDom: (self)->
    @table class: 'table table-striped latest-data', ->
      @tbody().setas 'tbodyEl', self
  #=========================================-

  append: (el, params)->
    @addHelper @tbodyEl, el, params

  storageInit: ->
    @bime @getCollectionField('items'), 'onItemAdded', 'onItemAdded'

  onItemAdded: (eventObject, item)->
    unless item.widget?
      @append ->
        @item storageItem: item

class Item extends RT.Widget

  TOPQUERY = 'topQuery'

  @register 'item'

  collectionName: 'items'

  #DOM-структура виджета ====================-
  createDom: (self)->
    @tr ->
      @dbname storageData: self.storageItem.data
      @queryCount storageData: self.storageItem.get('lastSample')
      for i in [0..4]
        @topQuery storageData: self.storageItem.get('lastSample').topFiveQueries[i] || {}
  #=========================================-

class DBname extends RT.Widget

  DBNAME = 'dbname'

  @register DBNAME

  collectionName: 'dbnames'

  storageInit: ->
    @bime @storageItem, 'onFieldChanged', 'onFieldChanged'

  #DOM-структура виджета ====================-
  createDom: (self)->
    @td class: DBNAME, ->
      @tn(self.storageItem.get(DBNAME)).setas 'nameEl', self
  #=========================================-

  onFieldChanged: (eventObject, field, value)->
    switch field
      when DBNAME then @nameEl.animNodeValue value

class QueryCount extends RT.Widget

  QUERYCOUNT = 'queryCount'
  COUNTCLASSNAME = 'countClassName'
  NBQUERIES = 'nbQueries'

  @register QUERYCOUNT

  collectionName: QUERYCOUNT

  storageInit: ->
    @bime @storageItem, 'onFieldChanged', 'onFieldChanged'

  #DOM-структура виджета ====================-
  createDom: (self)->
    @td class: 'query-count', ->
      @span().setas('spanEl', self).append ->
        @tn('').setas 'countEl', self
  #=========================================-

  onFieldChanged: (eventObject, field, value)->
    switch field
      when COUNTCLASSNAME then @spanEl.animClassName value
      when NBQUERIES then @countEl.animNodeValue value

class TopQuery extends RT.Widget

  TOPQUERY = 'topQuery'
  ELAPSEDCLASSNAME = 'elapsedClassName'
  FORMATELAPSED = 'formatElapsed'
  QUERY = 'query'

  @register TOPQUERY

  collectionName: TOPQUERY

  storageInit: ->
    @bime @storageItem, 'onFieldChanged', 'onFieldChanged'

  #DOM-структура виджета ====================-
  createDom: (self, params)->
    @td(class: self.storageItem.get(ELAPSEDCLASSNAME)).setas('elapsedClassName', self).append ->
      @tn(self.storageItem.get(FORMATELAPSED)).setas 'formatElapsedEl', self
      @div class: 'popover left', ->
        @div class: 'popover-content', ->
          @tn(self.storageItem.get(QUERY)).setas 'queryEl', self
        @div class: 'arrow'
  #=========================================-

  onFieldChanged: (eventObject, field, value)->
    switch field
      when ELAPSEDCLASSNAME then @elapsedClassName.animClassName value
      when FORMATELAPSED then @formatElapsedEl.animNodeValue value
      when QUERY then @queryEl.animNodeValue value
