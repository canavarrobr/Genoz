// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'analysis.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CompareEvent {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is CompareEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'CompareEvent()';
}


}

/// @nodoc
class $CompareEventCopyWith<$Res>  {
$CompareEventCopyWith(CompareEvent _, $Res Function(CompareEvent) __);
}


/// Adds pattern-matching-related methods to [CompareEvent].
extension CompareEventPatterns on CompareEvent {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( CompareEvent_Progress value)?  progress,TResult Function( CompareEvent_Done value)?  done,TResult Function( CompareEvent_Failed value)?  failed,TResult Function( CompareEvent_Cancelled value)?  cancelled,required TResult orElse(),}){
final _that = this;
switch (_that) {
case CompareEvent_Progress() when progress != null:
return progress(_that);case CompareEvent_Done() when done != null:
return done(_that);case CompareEvent_Failed() when failed != null:
return failed(_that);case CompareEvent_Cancelled() when cancelled != null:
return cancelled(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( CompareEvent_Progress value)  progress,required TResult Function( CompareEvent_Done value)  done,required TResult Function( CompareEvent_Failed value)  failed,required TResult Function( CompareEvent_Cancelled value)  cancelled,}){
final _that = this;
switch (_that) {
case CompareEvent_Progress():
return progress(_that);case CompareEvent_Done():
return done(_that);case CompareEvent_Failed():
return failed(_that);case CompareEvent_Cancelled():
return cancelled(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( CompareEvent_Progress value)?  progress,TResult? Function( CompareEvent_Done value)?  done,TResult? Function( CompareEvent_Failed value)?  failed,TResult? Function( CompareEvent_Cancelled value)?  cancelled,}){
final _that = this;
switch (_that) {
case CompareEvent_Progress() when progress != null:
return progress(_that);case CompareEvent_Done() when done != null:
return done(_that);case CompareEvent_Failed() when failed != null:
return failed(_that);case CompareEvent_Cancelled() when cancelled != null:
return cancelled(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( BigInt bytesDone,  BigInt bytesTotal)?  progress,TResult Function( String summaryJson,  String manifestJson)?  done,TResult Function( String message)?  failed,TResult Function()?  cancelled,required TResult orElse(),}) {final _that = this;
switch (_that) {
case CompareEvent_Progress() when progress != null:
return progress(_that.bytesDone,_that.bytesTotal);case CompareEvent_Done() when done != null:
return done(_that.summaryJson,_that.manifestJson);case CompareEvent_Failed() when failed != null:
return failed(_that.message);case CompareEvent_Cancelled() when cancelled != null:
return cancelled();case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( BigInt bytesDone,  BigInt bytesTotal)  progress,required TResult Function( String summaryJson,  String manifestJson)  done,required TResult Function( String message)  failed,required TResult Function()  cancelled,}) {final _that = this;
switch (_that) {
case CompareEvent_Progress():
return progress(_that.bytesDone,_that.bytesTotal);case CompareEvent_Done():
return done(_that.summaryJson,_that.manifestJson);case CompareEvent_Failed():
return failed(_that.message);case CompareEvent_Cancelled():
return cancelled();}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( BigInt bytesDone,  BigInt bytesTotal)?  progress,TResult? Function( String summaryJson,  String manifestJson)?  done,TResult? Function( String message)?  failed,TResult? Function()?  cancelled,}) {final _that = this;
switch (_that) {
case CompareEvent_Progress() when progress != null:
return progress(_that.bytesDone,_that.bytesTotal);case CompareEvent_Done() when done != null:
return done(_that.summaryJson,_that.manifestJson);case CompareEvent_Failed() when failed != null:
return failed(_that.message);case CompareEvent_Cancelled() when cancelled != null:
return cancelled();case _:
  return null;

}
}

}

/// @nodoc


class CompareEvent_Progress extends CompareEvent {
  const CompareEvent_Progress({required this.bytesDone, required this.bytesTotal}): super._();
  

 final  BigInt bytesDone;
 final  BigInt bytesTotal;

/// Create a copy of CompareEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CompareEvent_ProgressCopyWith<CompareEvent_Progress> get copyWith => _$CompareEvent_ProgressCopyWithImpl<CompareEvent_Progress>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is CompareEvent_Progress&&(identical(other.bytesDone, bytesDone) || other.bytesDone == bytesDone)&&(identical(other.bytesTotal, bytesTotal) || other.bytesTotal == bytesTotal));
}


@override
int get hashCode {
    return Object.hash(runtimeType,bytesDone,bytesTotal);
}

@override
String toString() {
    return 'CompareEvent.progress(bytesDone: $bytesDone, bytesTotal: $bytesTotal)';
}


}

/// @nodoc
abstract mixin class $CompareEvent_ProgressCopyWith<$Res> implements $CompareEventCopyWith<$Res> {
  factory $CompareEvent_ProgressCopyWith(CompareEvent_Progress value, $Res Function(CompareEvent_Progress) _then) = _$CompareEvent_ProgressCopyWithImpl;
@useResult
$Res call({
 BigInt bytesDone, BigInt bytesTotal
});




}
/// @nodoc
class _$CompareEvent_ProgressCopyWithImpl<$Res>
    implements $CompareEvent_ProgressCopyWith<$Res> {
  _$CompareEvent_ProgressCopyWithImpl(this._self, this._then);

  final CompareEvent_Progress _self;
  final $Res Function(CompareEvent_Progress) _then;

/// Create a copy of CompareEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? bytesDone = null,Object? bytesTotal = null,}) {
  return _then(CompareEvent_Progress(
bytesDone: null == bytesDone ? _self.bytesDone : bytesDone // ignore: cast_nullable_to_non_nullable
as BigInt,bytesTotal: null == bytesTotal ? _self.bytesTotal : bytesTotal // ignore: cast_nullable_to_non_nullable
as BigInt,
  ));
}


}

/// @nodoc


class CompareEvent_Done extends CompareEvent {
  const CompareEvent_Done({required this.summaryJson, required this.manifestJson}): super._();
  

 final  String summaryJson;
 final  String manifestJson;

/// Create a copy of CompareEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CompareEvent_DoneCopyWith<CompareEvent_Done> get copyWith => _$CompareEvent_DoneCopyWithImpl<CompareEvent_Done>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is CompareEvent_Done&&(identical(other.summaryJson, summaryJson) || other.summaryJson == summaryJson)&&(identical(other.manifestJson, manifestJson) || other.manifestJson == manifestJson));
}


@override
int get hashCode {
    return Object.hash(runtimeType,summaryJson,manifestJson);
}

@override
String toString() {
    return 'CompareEvent.done(summaryJson: $summaryJson, manifestJson: $manifestJson)';
}


}

/// @nodoc
abstract mixin class $CompareEvent_DoneCopyWith<$Res> implements $CompareEventCopyWith<$Res> {
  factory $CompareEvent_DoneCopyWith(CompareEvent_Done value, $Res Function(CompareEvent_Done) _then) = _$CompareEvent_DoneCopyWithImpl;
@useResult
$Res call({
 String summaryJson, String manifestJson
});




}
/// @nodoc
class _$CompareEvent_DoneCopyWithImpl<$Res>
    implements $CompareEvent_DoneCopyWith<$Res> {
  _$CompareEvent_DoneCopyWithImpl(this._self, this._then);

  final CompareEvent_Done _self;
  final $Res Function(CompareEvent_Done) _then;

/// Create a copy of CompareEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? summaryJson = null,Object? manifestJson = null,}) {
  return _then(CompareEvent_Done(
summaryJson: null == summaryJson ? _self.summaryJson : summaryJson // ignore: cast_nullable_to_non_nullable
as String,manifestJson: null == manifestJson ? _self.manifestJson : manifestJson // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class CompareEvent_Failed extends CompareEvent {
  const CompareEvent_Failed({required this.message}): super._();
  

 final  String message;

/// Create a copy of CompareEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CompareEvent_FailedCopyWith<CompareEvent_Failed> get copyWith => _$CompareEvent_FailedCopyWithImpl<CompareEvent_Failed>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is CompareEvent_Failed&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode {
    return Object.hash(runtimeType,message);
}

@override
String toString() {
    return 'CompareEvent.failed(message: $message)';
}


}

/// @nodoc
abstract mixin class $CompareEvent_FailedCopyWith<$Res> implements $CompareEventCopyWith<$Res> {
  factory $CompareEvent_FailedCopyWith(CompareEvent_Failed value, $Res Function(CompareEvent_Failed) _then) = _$CompareEvent_FailedCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$CompareEvent_FailedCopyWithImpl<$Res>
    implements $CompareEvent_FailedCopyWith<$Res> {
  _$CompareEvent_FailedCopyWithImpl(this._self, this._then);

  final CompareEvent_Failed _self;
  final $Res Function(CompareEvent_Failed) _then;

/// Create a copy of CompareEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(CompareEvent_Failed(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class CompareEvent_Cancelled extends CompareEvent {
  const CompareEvent_Cancelled(): super._();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is CompareEvent_Cancelled);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'CompareEvent.cancelled()';
}


}




// dart format on
