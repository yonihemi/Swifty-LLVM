import llvmc

/// A constant array in LLVM IR.
public struct ArrayConstant: IRValue, Hashable {

  /// A handle to the LLVM object wrapped by this instance.
  public let llvm: LLVMValueRef

  /// The number of elements in the array.
  public let count: Int

  /// Creates a constant array of `type` in `module`, filled with the contents of `elements`.
  ///
  /// - Requires: The type of each element in `contents` is `type`.
  public init<S: Sequence>(
    of type: IRType, containing elements: S, in module: inout Module
  ) where S.Element == IRValue {
    var values = elements.map({ $0.llvm as Optional })
    self.llvm = LLVMConstArray(type.llvm, &values, UInt32(values.count))
    self.count = values.count
  }

  /// Creates a constant array of `i8` in `module`, filled with the contents of `bytes`.
  public init<S: Sequence>(bytes: S, in module: inout Module) where S.Element == UInt8 {
    let i8 = IntegerType(8, in: &module)
    self.init(of: i8, containing: bytes.map({ i8.constant(UInt64($0)) }), in: &module)
  }

}

extension ArrayConstant: BidirectionalCollection {

  public typealias Index = Int

  public typealias Element = IRValue

  public var startIndex: Int { 0 }

  public var endIndex: Int { count }

  public func index(after position: Int) -> Int {
    precondition(position < count, "index is out of bounds")
    return position + 1
  }

  public func index(before position: Int) -> Int {
    precondition(position > 0, "index is out of bounds")
    return position - 1
  }

  public subscript(position: Int) -> IRValue {
    precondition(position >= 0 && position < count, "index is out of bounds")
    return AnyValue(LLVMGetAggregateElement(llvm, UInt32(position)))
  }

}