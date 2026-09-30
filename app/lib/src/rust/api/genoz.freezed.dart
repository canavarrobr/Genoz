// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'genoz.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ImportEvent {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ImportEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'ImportEvent()';
}


}

/// @nodoc
class $ImportEventCopyWith<$Res>  {
$ImportEventCopyWith(ImportEvent _, $Res Function(ImportEvent) __);
}


/// Adds pattern-matching-related methods to [ImportEvent].
extension ImportEventPatterns on ImportEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ImportEvent_Progress value)?  progress,TResult Function( ImportEvent_Done value)?  done,TResult Function( ImportEvent_Failed value)?  failed,TResult Function( ImportEvent_Cancelled value)?  cancelled,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ImportEvent_Progress() when progress != null:
return progress(_that);case ImportEvent_Done() when done != null:
return done(_that);case ImportEvent_Failed() when failed != null:
return failed(_that);case ImportEvent_Cancelled() when cancelled != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ImportEvent_Progress value)  progress,required TResult Function( ImportEvent_Done value)  done,required TResult Function( ImportEvent_Failed value)  failed,required TResult Function( ImportEvent_Cancelled value)  cancelled,}){
final _that = this;
switch (_that) {
case ImportEvent_Progress():
return progress(_that);case ImportEvent_Done():
return done(_that);case ImportEvent_Failed():
return failed(_that);case ImportEvent_Cancelled():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ImportEvent_Progress value)?  progress,TResult? Function( ImportEvent_Done value)?  done,TResult? Function( ImportEvent_Failed value)?  failed,TResult? Function( ImportEvent_Cancelled value)?  cancelled,}){
final _that = this;
switch (_that) {
case ImportEvent_Progress() when progress != null:
return progress(_that);case ImportEvent_Done() when done != null:
return done(_that);case ImportEvent_Failed() when failed != null:
return failed(_that);case ImportEvent_Cancelled() when cancelled != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( ImportPhase phase,  BigInt bytesDone,  BigInt bytesTotal)?  progress,TResult Function( String reportJson)?  done,TResult Function( String message)?  failed,TResult Function()?  cancelled,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ImportEvent_Progress() when progress != null:
return progress(_that.phase,_that.bytesDone,_that.bytesTotal);case ImportEvent_Done() when done != null:
return done(_that.reportJson);case ImportEvent_Failed() when failed != null:
return failed(_that.message);case ImportEvent_Cancelled() when cancelled != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( ImportPhase phase,  BigInt bytesDone,  BigInt bytesTotal)  progress,required TResult Function( String reportJson)  done,required TResult Function( String message)  failed,required TResult Function()  cancelled,}) {final _that = this;
switch (_that) {
case ImportEvent_Progress():
return progress(_that.phase,_that.bytesDone,_that.bytesTotal);case ImportEvent_Done():
return done(_that.reportJson);case ImportEvent_Failed():
return failed(_that.message);case ImportEvent_Cancelled():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( ImportPhase phase,  BigInt bytesDone,  BigInt bytesTotal)?  progress,TResult? Function( String reportJson)?  done,TResult? Function( String message)?  failed,TResult? Function()?  cancelled,}) {final _that = this;
switch (_that) {
case ImportEvent_Progress() when progress != null:
return progress(_that.phase,_that.bytesDone,_that.bytesTotal);case ImportEvent_Done() when done != null:
return done(_that.reportJson);case ImportEvent_Failed() when failed != null:
return failed(_that.message);case ImportEvent_Cancelled() when cancelled != null:
return cancelled();case _:
  return null;

}
}

}

/// @nodoc


class ImportEvent_Progress extends ImportEvent {
  const ImportEvent_Progress({required this.phase, required this.bytesDone, required this.bytesTotal}): super._();
  

 final  ImportPhase phase;
 final  BigInt bytesDone;
 final  BigInt bytesTotal;

/// Create a copy of ImportEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ImportEvent_ProgressCopyWith<ImportEvent_Progress> get copyWith => _$ImportEvent_ProgressCopyWithImpl<ImportEvent_Progress>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ImportEvent_Progress&&(identical(other.phase, phase) || other.phase == phase)&&(identical(other.bytesDone, bytesDone) || other.bytesDone == bytesDone)&&(identical(other.bytesTotal, bytesTotal) || other.bytesTotal == bytesTotal));
}


@override
int get hashCode {
    return Object.hash(runtimeType,phase,bytesDone,bytesTotal);
}

@override
String toString() {
    return 'ImportEvent.progress(phase: $phase, bytesDone: $bytesDone, bytesTotal: $bytesTotal)';
}


}

/// @nodoc
abstract mixin class $ImportEvent_ProgressCopyWith<$Res> implements $ImportEventCopyWith<$Res> {
  factory $ImportEvent_ProgressCopyWith(ImportEvent_Progress value, $Res Function(ImportEvent_Progress) _then) = _$ImportEvent_ProgressCopyWithImpl;
@useResult
$Res call({
 ImportPhase phase, BigInt bytesDone, BigInt bytesTotal
});




}
/// @nodoc
class _$ImportEvent_ProgressCopyWithImpl<$Res>
    implements $ImportEvent_ProgressCopyWith<$Res> {
  _$ImportEvent_ProgressCopyWithImpl(this._self, this._then);

  final ImportEvent_Progress _self;
  final $Res Function(ImportEvent_Progress) _then;

/// Create a copy of ImportEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? phase = null,Object? bytesDone = null,Object? bytesTotal = null,}) {
  return _then(ImportEvent_Progress(
phase: null == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as ImportPhase,bytesDone: null == bytesDone ? _self.bytesDone : bytesDone // ignore: cast_nullable_to_non_nullable
as BigInt,bytesTotal: null == bytesTotal ? _self.bytesTotal : bytesTotal // ignore: cast_nullable_to_non_nullable
as BigInt,
  ));
}


}

/// @nodoc


class ImportEvent_Done extends ImportEvent {
  const ImportEvent_Done({required this.reportJson}): super._();
  

 final  String reportJson;

/// Create a copy of ImportEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ImportEvent_DoneCopyWith<ImportEvent_Done> get copyWith => _$ImportEvent_DoneCopyWithImpl<ImportEvent_Done>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ImportEvent_Done&&(identical(other.reportJson, reportJson) || other.reportJson == reportJson));
}


@override
int get hashCode {
    return Object.hash(runtimeType,reportJson);
}

@override
String toString() {
    return 'ImportEvent.done(reportJson: $reportJson)';
}


}

/// @nodoc
abstract mixin class $ImportEvent_DoneCopyWith<$Res> implements $ImportEventCopyWith<$Res> {
  factory $ImportEvent_DoneCopyWith(ImportEvent_Done value, $Res Function(ImportEvent_Done) _then) = _$ImportEvent_DoneCopyWithImpl;
@useResult
$Res call({
 String reportJson
});




}
/// @nodoc
class _$ImportEvent_DoneCopyWithImpl<$Res>
    implements $ImportEvent_DoneCopyWith<$Res> {
  _$ImportEvent_DoneCopyWithImpl(this._self, this._then);

  final ImportEvent_Done _self;
  final $Res Function(ImportEvent_Done) _then;

/// Create a copy of ImportEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? reportJson = null,}) {
  return _then(ImportEvent_Done(
reportJson: null == reportJson ? _self.reportJson : reportJson // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class ImportEvent_Failed extends ImportEvent {
  const ImportEvent_Failed({required this.message}): super._();
  

 final  String message;

/// Create a copy of ImportEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ImportEvent_FailedCopyWith<ImportEvent_Failed> get copyWith => _$ImportEvent_FailedCopyWithImpl<ImportEvent_Failed>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ImportEvent_Failed&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode {
    return Object.hash(runtimeType,message);
}

@override
String toString() {
    return 'ImportEvent.failed(message: $message)';
}


}

/// @nodoc
abstract mixin class $ImportEvent_FailedCopyWith<$Res> implements $ImportEventCopyWith<$Res> {
  factory $ImportEvent_FailedCopyWith(ImportEvent_Failed value, $Res Function(ImportEvent_Failed) _then) = _$ImportEvent_FailedCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$ImportEvent_FailedCopyWithImpl<$Res>
    implements $ImportEvent_FailedCopyWith<$Res> {
  _$ImportEvent_FailedCopyWithImpl(this._self, this._then);

  final ImportEvent_Failed _self;
  final $Res Function(ImportEvent_Failed) _then;

/// Create a copy of ImportEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(ImportEvent_Failed(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class ImportEvent_Cancelled extends ImportEvent {
  const ImportEvent_Cancelled(): super._();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ImportEvent_Cancelled);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'ImportEvent.cancelled()';
}


}




// dart format on
