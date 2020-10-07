package io.colyseus.serializer.schema.types;

class OrderedMapIterator<K,V> {
    var map : OrderedMap<K,V>;
    var index : Int = 0;
    public function new(omap:OrderedMap<K,V>) { map = omap; }
    public function hasNext() : Bool { return index < map._keys.length;}
    public function next() : V { return map.get(map._keys[index++]); }
}

// class OrderedMap<K, V> implements IMap<K, V> {
@:keep
class OrderedMap<K, V> {
    var map:Map<K, V>;

    @:allow(OrderedMapIterator) // TODO: why this doesn't seem to work?
    public var _keys:Array<K>; // FIXME: this should be private
    var idx = 0;

    public function new(_map: Map<K, V> = null) {
       _keys = [];
       map = (_map != null) ? _map : new Map<K, V>();
    }

    public function set(key: K, value: V) {
        if(!map.exists(key)) _keys.push(key);
        map[key] = value;
    }

    public function toString() {
        var _ret = ''; var _cnt = 0; var _len = _keys.length;
        for(k in _keys) _ret += '$k => ${map.get(k)}${(_cnt++<_len-1?", ":"")}';
        return '{$_ret}';
    }

    public function iterator() return new OrderedMapIterator<K,V>(this);
    public function remove(key: K) return map.remove(key) && _keys.remove(key);
    public function exists(key: K) return map.exists(key);
    public function get(key: K) return map.get(key);
    public inline function keys() return _keys.iterator();
}


@:keep
@:generic
class MapSchema<T> implements IRef implements ISchemaCollection {
  public var __refId: Int;
  public var _childType: Dynamic;

  public function getIndex(fieldIndex: Int) {
    return this.indexes[fieldIndex];
  }

  public function setIndex(fieldIndex: Int, dynamicIndex: Dynamic) {
    this.indexes[fieldIndex] = dynamicIndex;
  }

  public function getByIndex(fieldIndex: Int): Dynamic {
    return this.items.get(this.indexes[fieldIndex]);
  }

  public function setByIndex(index: Int, dynamicIndex: Dynamic, value: Dynamic): Void {
    this.indexes[index] = dynamicIndex;
		this.items.set(dynamicIndex, value);
  }

  public function deleteByIndex(fieldIndex: Int): Void {
    var index = this.indexes[fieldIndex];
    this.items.remove(index);
    this.indexes.remove(fieldIndex);
  }

  public var items:OrderedMap<String, T> = new OrderedMap<String, T>();
  public var indexes:Map<Int, String> = new Map<Int, String>();

  public var length(get, null): Int;
  function get_length() { return this.items._keys.length; }

  public dynamic function onAdd(item:T, key:String):Void {}
  public dynamic function onChange(item:T, key:String):Void {}
  public dynamic function onRemove(item:T, key:String):Void {}

  public function new() {}

	public function moveEventHandlers(previousInstance: Dynamic) {
    this.onAdd = previousInstance.onAdd;
    this.onChange = previousInstance.onChange;
    this.onRemove = previousInstance.onRemove;
  }

  public function clone():MapSchema<T> {
    var cloned = new MapSchema<T>();

    for (key in this.items.keys()) {
      cloned.items.set(key, this.items.get(key));
    }

    cloned.onAdd = this.onAdd;
    cloned.onChange = this.onChange;
    cloned.onRemove = this.onRemove;

    return cloned;
  }

  public function iterator() {
    return this.items.iterator();
  }

  @:arrayAccess
  public inline function get(key:String) {
    return this.items.get(key);
  }

  @:arrayAccess
  public inline function arrayWrite(key:String, value:T):T {
    this.items.set(key, value);
    return value;
  }

  public function toString () {
    var data = [];
    for (key in this.items.keys()) {
      data.push(key + " => " + this.items.get(key));
    }
    return "MapSchema ("+ Lambda.count(this.items) +") { " + data.join(", ") + " }";
  }
}