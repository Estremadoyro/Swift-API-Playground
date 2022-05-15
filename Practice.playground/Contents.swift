import UIKit

// Person   -/-/- > Passport
// Passport - - -> Person

print("-- Retain Cycle --")
class Person {
  weak var passport: Passport?

  init(_ passport: Passport?) {
    self.passport = passport
  }

  deinit { print("\(self) deinited") }
}

class Passport {
  var person: Person?

  deinit { print("\(self) deinited") }
}

var passport: Passport? = Passport()
var person: Person? = Person(passport)
passport?.person = person

passport = nil
person = nil

// print("End")

/// # Indirect enums (indirect enum)
print("-- Indirect Enums (indirect) --")
indirect enum LinkedListItem<T> {
  case endPoint(value: T)
  case linkNode(value: T, next: LinkedListItem)
}

var third = LinkedListItem.endPoint(value: "Third")
var second = LinkedListItem.linkNode(value: "Second", next: third)
var first = LinkedListItem.linkNode(value: "First", next: second)

var currentNode = first

listLoop: while true {
  switch currentNode {
    case .endPoint(let value):
      print("endpoint \(value)")
      break listLoop
    case .linkNode(let value, let next):
      print("linkNode: \(value)")
      currentNode = next
  }
}

/// # Autoclosure (@autoclosure () -> String)
// Doesn't take arguments
// Lets delay evaluation of the closure, its content doesn't get executed until told so
print("-- Autoclosure --")
var customersInLine = ["Chris", "Alex", "Ewa", "Barry", "Daniella"]
print(customersInLine.count)
// prints 5

let customerProvider = { customersInLine.remove(at: 0) }
print(customersInLine.count)
// prints 5

print("Now serving \(customerProvider())!")
// prints "Now serving Chris!

print(customersInLine.count)
// prints 4

// The customerProvider is now taken as a String instead of a closure
func serve(customer customerProvider: @autoclosure () -> String) {
  print("Now serving \(customerProvider())!")
}

serve(customer: customersInLine.remove(at: 0))

/// # Dispatch Queues
// Execute and ends in order (FIFO)
/// # Serial Dispatch Queue
print("-- Serial DispatchQueue --")
let serialQueue = DispatchQueue(label: "wof")
serialQueue.async {
  print("Task 1 started")
  // Do some stuff
  print("Task 1 finished")
}

serialQueue.async {
  print("Task 2 started")
  // Do some work
  print("Task 2 finished")
}

/// # Concurrent Dispatch Queue
print("-- Concurrent DispatchQueue --")
let concurrentQueue = DispatchQueue(label: "concurrent wof", attributes: .concurrent)
concurrentQueue.async {
  print("Task 1 started")
  // Do some stuff
  print("Task 1 finished")
}

concurrentQueue.async {
  print("Task 2 started")
  // Do stuff
  print("Task 2 finished")
}

print("-- Barrier Flag (DispatchQueue) --")
final class Messenger {
  private var messages: [String] = []

  private var queue = DispatchQueue(label: "wof wof", attributes: .concurrent)

  var lastMessage: String? {
    return queue.sync {
      messages.last
    }
  }

  func postMessage(_ newMessage: String) {
    // Flag is set, access to messages (write) is now thread-safe
    // After all tasks are finished, messages.append() will be executed
    queue.sync(flags: .barrier) {
      messages.append(newMessage)
    }
  }
}

let messenger = Messenger()
messenger.postMessage("Hello mi brudda")

print(messenger.lastMessage ?? "")

/// # Main Thread
print("-- Main Thread + Bacground Thread")
func fetchData() {
  print("Fetching heavy data owo")
}

let concurrentQueueMainThread = DispatchQueue(label: "wof main thread default", attributes: .concurrent)
let customQueue = DispatchQueue(label: "wof?", qos: .userInteractive, attributes: .concurrent, autoreleaseFrequency: .inherit, target: .global())
concurrentQueueMainThread.async {
  fetchData()

  DispatchQueue.main.async {
    /// # Access an reload UI in the main queue
    // Reload table view
    // tableView.reloadData()
  }
}

/// # Random request
func fetchRequest<T: Decodable>(completion: @escaping ((T?, URLResponse?, Error?) -> Void)) {
  URLSession.shared.dataTask(with: URL(string: "https://www.google.com")!) { data, response, error in
    do {
      guard error != nil else { return }
      if let data = data {
        let parsedData = try JSONDecoder().decode(T.self, from: data)
        completion(parsedData, response, error)
      }
    } catch (let error) {
      completion(nil, nil, error)
    }
  }.resume()
}

// MARK: - Result Enum (Result<Any, Error>)

/// Has 2 cases: success() & failure()
// Used to define the outcome of a method, it can either be sucessful (Any) or failure (Error)
enum EvenNumberError: Error {
  case emptyArray
}

func evenNumbers(in collection: [Int]) -> Result<[Int], EvenNumberError> {
  guard !collection.isEmpty else {
    return Result.failure(EvenNumberError.emptyArray)
  }

  let evenNumbers = collection.filter { $0 % 2 == 0 }
  return .success(evenNumbers)
}

let numbers = [2, 5, 8, 12, 16, 23]
// print(evenNumbers(in: [Int]()))
// print(evenNumbers(in: numbers))
func handleResult() {
  switch evenNumbers(in: numbers) {
    case .success(let evenNumbers):
      print("Success - \(evenNumbers)")
    case .failure(let error):
      print("Failure - Fetching even numbers failed with \(error)")
  }
}

func handleResultWithTransformation() {
  enum CommonErrorType: Error {
    case otherError(error: Error)
  }

  let evenNumbers1 = evenNumbers(in: numbers).mapError { evenNumbersError in
    CommonErrorType.otherError(error: evenNumbersError)
  }
  print("Even numbers with transformed error: \(evenNumbers1)")

  let evenNumbers2 = evenNumbers(in: numbers).map { evenNumbersSuccess -> [String] in
    // Parses Result<[Int], Error> -> Result<[String], Error>
    evenNumbersSuccess.map { String($0) }
  }
  print("Even numbers with transformed value: \(evenNumbers2)")

  // Map the result using a method that can fail, this using flatMap and returing Result enum
  let evenNumbers3 = evenNumbers(in: numbers).flatMap { evenNumbers -> Result<Int, EvenNumberError> in
    guard let firstEvenNumber = evenNumbers.first else {
      return .failure(EvenNumberError.emptyArray)
    }
    return .success(firstEvenNumber)
  }
  print("Even numbers wiht a failable transformation returns another Result enum: \(evenNumbers3)")

  // Error can have its own default value, by converting it to another Result with a default .success() value
  let fallbackEvenNumbers = [2, 4, 6, 8, 10]
  let defaultNumberResult = evenNumbers(in: numbers).flatMapError { error -> Result<[Int], EvenNumberError> in
    if error == .emptyArray {
      return .success(fallbackEvenNumbers)
    }
    return .failure(error)
  }
  print("Even numbers with default result by transforming its Error into another Result enum with a custom .success() \(defaultNumberResult)")
}

func oddNumbers(in collection: [Int]) throws -> [Int] {
  guard !collection.isEmpty else {
    throw EvenNumberError.emptyArray
  }
  let oddNumbers = collection.filter { number in number % 2 == 1 }
  return oddNumbers
}

func handleOddNummberResult() {
  // Wrapping it inside the Result.init() in order to access its .success() and .failure() cases
  // Result.init() requires a THROWING closure to return its 2 cases
  let oddNumbersResult = Result { try oddNumbers(in: numbers) }
  // It can now use Result cases
  switch oddNumbersResult {
    case .success(let success):
      print("Found odd numbers: \(success)")
    case .failure(let failure):
      print("Error finding odd numbers: \(failure)")
  }
}

// Converts a Result into Throwing Expression by using it inside the Result initlizer
let a = try evenNumbers(in: numbers).get()
print(a)

let numbers1 = [1, 2, 3, 4]

let mapped = numbers1.map { Array(repeating: $0, count: $0) }
// [[1], [2, 2], [3, 3, 3], [4, 4, 4, 4]]

let flatMapped = numbers1.flatMap { Array(repeating: $0, count: $0) }
// [1, 2, 2, 3, 3, 3, 4, 4, 4, 4]

// MARK: - Tasks (async / await)

// Asynchronous context to call async marked APIs and perform work in the background
// Encapsulates asynchronouus code. Control the way code is run, managed and cancelled
print("--- Tasks --")
// Method performs asynchronous work (async)
// With Async
func fetchImages() async throws -> [UIImage] {
  // Suspend the method with await, and then run the deprecated method that used closures
  return try await withCheckedThrowingContinuation { continuation in
    fetchImages { result in
      continuation.resume(with: result)
    }
  }
//  return [#imageLiteral(resourceName: "senku.jpeg")]
}

// With closure callbacks (Using Result enum)
@available(*, deprecated, renamed: "fetchImages()")
func fetchImages(completion: @escaping (Result<[UIImage], Error>) -> Void) {}

// With closure callbacks (Without Result enum)
func fetchImages(completion: @escaping (UIImage?, Error?) -> Void) {}

/// # Await (Used to call async methods)
/// # *Waits a callback from the async method*
func runAsyncTask() {
  Task(operation: {
    do {
      let images = try await fetchImages()
      // Without async/await
      fetchImages { result in
        switch result {
          case .success(let image):
            print(image)
          case .failure(let error):
            print(error)
        }
      }
      //
      print("Fetched \(images.count) images")
    } catch {
      print("Fetching images failed with error: \(error)")
    }
  })
}

// MARK: - Operation Queues

print("-- Operation Queues --")

struct OperationExample {
  func operations() {
    // Instance of operation
    let operation = BlockOperation()

    // Set it's QOS
//    operation.queuePriority = .veryLow

    // Executing a task
    operation.addExecutionBlock {
      print("Task 1")
    }

    operation.addExecutionBlock {
      print("Task 2")
    }

    let operation2 = BlockOperation()
    operation2.addExecutionBlock {
      print("operation 2")
    }

    // Create queue
    let queue = OperationQueue()

    // Now, using queues you add QOS to the queue and not the BlockOperation
    queue.qualityOfService = .utility
    queue.addOperations([operation, operation2], waitUntilFinished: false)

//    operation.start()
  }
}

let op = OperationExample()
op.operations()

// MARK: - Collection transformations (.map, .flatMap, .compactMap)

print("-- Collection Transformation --")
extension Bundle {
  func loadFiles(named fileNames: [String]) throws -> [Any] {
    return try fileNames
    // Returns new sequence of all non-nil values
    // flatMap will skip all files that don't exist
//      .flatMap { name -> Data? in
//        url(forResource: name, withExtension: nil)
//      }
//      .map(Data.init)
  }
}

func sequenceTransformations() {
  do {
    let a = try Bundle.main.loadFiles(named: ["woof", "woof 2"])
    print(a)
  } catch {
    print(error)
  }

  let possibleNumbers: [String] = ["1", "2", "three", "///4///", "5"]

  /// # .map()
  let mapped: [Int?] = possibleNumbers.map { str in
    Int(str)
  }

  /// # .compactMap()
  let compactMapped: [Int] = possibleNumbers.compactMap { str in
    Int(str)
  }

  /// # .flatMap()
  /// .map().joined()
  let numbers: [Int] = [1, 2, 5]
  let flatMapped: [Int] = numbers
    .flatMap { Array(repeating: $0, count: $0) }

  print("map: \(mapped)")
  print("compactMap: \(compactMapped)")
  print("flatMap: \(flatMapped)")
}

sequenceTransformations()

// MARK: - Optional Type

let x: String? = Optional("Hello world")
let x1: String? = "Hello mars"

if let y = x {
  print(y)
}

enum NewOptional<Wrapped> {
//  case none
  case some(Wrapped)
  init(_ some: Wrapped) {
    self = .some(some)
  }
}

func implementNewOptional<T>(value: T) -> T {
  let y: NewOptional<T> = .init(value)
  switch y {
//    case .none:
//      return T.self
    case .some(let value):
      return value
  }
}

print(implementNewOptional(value: "Wakandaaa"))

// MARK: - Attributes

@discardableResult // Disable warning for not using the output value
@available(iOS 10.0, macOS 10.12, *) // Availability for certain platform&versions
func unusedstatement() -> Int { return 1 }

// MARK: - Property Wrapper

@propertyWrapper
struct SomeWrapper {
  // { get; } value when set
  var wrappedValue: Int
  var projectedValue: SomeProjection {
    return SomeProjection(wrapper: self)
  }

  var someValue: Double

  init() {
    self.wrappedValue = 100
    self.someValue = 12.3
  }

  init(wrappedValue: Int) {
    self.someValue = 45.6
    self.wrappedValue = wrappedValue
  }

  init(wrappedValue value: Int, custom: Double) {
    self.wrappedValue = value
    self.someValue = custom
  }
}

struct SomeProjection {
  var wrapper: SomeWrapper
  var customValue: Int

  init(wrapper: SomeWrapper) {
    self.wrapper = wrapper
    self.customValue = 100 * self.wrapper.wrappedValue
  }
}

struct SomeStruct {
  // Uses init()
  @SomeWrapper var a: Int

  // Uses init(wrappedValue:) aka .init() with 1 parameter
  @SomeWrapper var b: Int = 10

  // Both use init(wrappedValue:custom:)
  @SomeWrapper(custom: 98.7) var c = 30

  @SomeWrapper(wrappedValue: 30, custom: 98.7) var d

  func show() {
    print("wrapper value: \(d)")
    print("wrapper value: \($d.customValue)")
  }
}

let randomStruct = SomeStruct()
randomStruct.show()

// MARK: - Atomic Properties (Property Wrapper)

print("-- Atomic Properties --")

@propertyWrapper
struct Atomic<Value> {
  private var value: Value
  private let lock = NSLock()
  var wrappedValue: Value {
    get { return load() }
    set { store(newValue: newValue) }
  }

  init(wrappedValue value: Value) {
    self.value = value
  }

  private func load() -> Value {
    // Attempts to acquire a Lock, blocking the Thread until doing so
    lock.lock()
    // Gives up on the lock before exiting the function
    defer { lock.unlock() }
    return value
  }

  private mutating func store(newValue: Value) {
    print("New value: \(value)")
    // Attempts to acquire a Lock, blocking the Thread until doing so
    lock.lock()
    // Gives up on the lock before exiting the function
    defer { lock.unlock() }
    value = newValue
  }
}

struct AtomicStruct {
  // Can be safely access by multiple threads
  @Atomic var counter: Int = 1
  func show() {
    print("Atomic wrapped property: \(counter)")
  }
}

let atomicStruct = AtomicStruct()
atomicStruct.show()

// MARK: - Rappi Challenge

// Minimum number of players
// Each player must have a skill rating within a certain range
/// # Input: List of players skill levels with upper and lower bounds
let skills: [Int] = [12, 4, 6, 13, 5, 10]
/// # Input: Min. amount of players
let minPlayers: Int = 3
/// # Input: Lower skill bound
let minLevel: Int = 4
/// # Input: Upper skill bound (inclusive)
let maxLevel: Int = 10

/// # Output: How many teams can be created -> Int

// 5
// 5 * factorial(4) = 5 * 24 = 120
// 4
// 4 * facotiral(3) = 4 * 6 = 24
// 3
// 3 * factorial(2) = 3 * 2 = 6
// 2
// 2 * factorial(1) = 2 * 1 = 2
// 1
// return 1

func factorial(_ n: Int) -> Double {
  return n < 2 ? 1 : Double(n) * factorial(n - 1)
}

func createTeams(skills: [Int], minPlayers: Int, minLevel: Int, maxLevel: Int) -> Int {
  let skilledPlayers = skills.filter { skilledPlayer in
    skilledPlayer >= minLevel && skilledPlayer <= maxLevel
  }

  let n = skilledPlayers.count
  var r = minPlayers
  var result: Double = 0

  while r <= n {
    result += factorial(n) / (factorial(n) * factorial(n - r))
    r += 1
  }
  return Int(result)
}

createTeams(skills: skills, minPlayers: minPlayers, minLevel: minLevel, maxLevel: maxLevel)
