dynamic createArray(List<int> dims) {
  if (dims.length > 0) {
    var dim = dims.first;
    var newDims = List<int>.from(dims);
    newDims.removeAt(0);
    var array = List.generate(dim, (index) => createArray(newDims));
    return array;
  } else {
    return null;
  }
}

dynamic addToArray(dynamic array, List<dynamic> coors, dynamic value) {
  if (coors.length > 0) {
    var index = coors.first;
    var newArray = array[index];
    coors.removeAt(0);

    array[index] = addToArray(newArray, coors, value);
    return array;
  } else {
    return value;
  }
}

addToArrayMultiple(dynamic array, List<dynamic> coors, dynamic value) {
  var newValue = value;
  var newCoors = coors;
  if (newCoors.length > 0) {
    var indexList = newCoors.first;
    newCoors.removeAt(0);
    var newArray = array;

    for (var index in indexList) {
      newArray[index] = addToArrayMultiple(newArray[index], newCoors, newValue);
    }
    return newArray;
  } else {
    return newValue;
  }
}

dynamic expandCoordinates(dynamic coors) {
  if (coors.length == 1) {
    return coors.first;
  } else {
    var firsts = coors.first;
    coors.removeAt(0);
    var subs = expandCoordinates(coors);
    var res = List.empty(growable: true);
    for (var first in firsts) {
      for (var sub in subs) {
        var subres = List.from([first]);
        if (sub is int) {
          subres.add(sub);
        } else {
          subres.addAll(sub);
        }
        res.add(subres);
      }
    }
    return res;
  }
}

dynamic addArrays(dynamic a, dynamic b) {
  if (a == null || b == null) {
    return null;
  }
  if (!(a is List)) {
    return a + b;
  } else {
    var res = List<dynamic>.empty(growable: true);
    for (var idx in List.generate(a.length, (index) => index)) {
      res.add(addArrays(a[idx], b[idx]));
    }
    return res;
  }
}

dynamic divideArrayBy(dynamic array, double value) {
  if (!(array is List)) {
    if (array == null) {
      return null;
    } else {
      return array / value;
    }
  } else {
    var res = List<dynamic>.empty(growable: true);
    for (var _array in array) {
      res.add(divideArrayBy(_array, value));
    }
    return res;
  }
}
