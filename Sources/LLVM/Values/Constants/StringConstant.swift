import llvmc

/// A constant character string in LLVM IR.
public struct StringConstant: IRValue, Hashable {

  /// A handle to the LLVM object wrapped by this instance.
  public let llvm: LLVMValueRef

  public let context: ContextHandle

  /// Creates an instance with `text` in `module`, appending a null terminator to the string iff
  /// `nullTerminated` is `true`.
  public init(_ text: String, nullTerminated: Bool = true, in module: inout Module) {
    self.context = module.context
    self.llvm = module.inContext {
      text.withCString { (s) in
        LLVMConstStringInContext(module.context.raw, s, UInt32(text.utf8.count), nullTerminated ? 0 : 1)
      }
    }
  }

  /// Creates an instance with `v`, failing iff `v` is not a constant string value.
  public init?(_ v: IRValue) {
    if (v.inContext { LLVMIsAConstantDataSequential(v.llvm) != nil && LLVMIsConstantString(v.llvm) != 0 }) {
      self.llvm = v.llvm
      self.context = v.context
    } else {
      return nil
    }
  }

  /// The value of this constant.
  public var value: String {
    inContext {
      .init(from: llvm) { (h, count) in
        // Decrement `count` if the string is null-terminated.
        guard let s = LLVMGetAsString(h, count) else { return nil }
        if s[count!.pointee - 1] == 0 { count!.pointee -= 1 }
        return s
      } ?? ""
    }
  }

}
