unit Manager.Intf;

interface

uses
  System.SysUtils, Async.Promise, Async.Promise.Manager;

type
  /// <summary>
  /// Provides an interface for processing and transforming Markdown text.
  /// </summary>
  /// <remarks>
  /// This interface defines a single method, <c>Process</c>, which accepts a raw string input
  /// and returns a processed Markdown version of that string. Implementations of <c>IMarkDown</c>
  /// are expected to handle Markdown formatting, conversion, or parsing as needed.
  /// </remarks>
  IMarkDown = interface
    ['{DCF9A4DF-F5C7-4EC9-8EF1-A1194F46DE17}']
    /// <summary>
    /// Processes the specified input string and returns the corresponding Markdown formatted output.
    /// </summary>
    /// <param name="Value">
    /// The raw string input to be processed.
    /// </param>
    /// <returns>
    /// A string containing the processed Markdown output.
    /// </returns>
    function Process(const Value: string): string;
  end;

  /// <summary>
  /// Provides an interface for displaying text and managing visual output in a user interface.
  /// </summary>
  /// <remarks>
  /// <para>
  /// The <c>IDisplayer</c> interface defines methods for presenting text, handling streaming content,
  /// and managing scroll behavior within a display component. It is designed to be implemented
  /// by classes that render text-based output, such as memo controls or web browser components.
  /// </para>
  /// <para>
  /// Methods include displaying complete text or incremental streams of text, scrolling to the top or bottom,
  /// and clearing the display. Implementations of this interface ensure a consistent way of interacting
  /// with various user interface elements that show text output.
  /// </para>
  /// </remarks>
  IDisplayer = interface
    ['{D7D47290-0C2F-4A8B-9A54-12EAC9C47387}']
    /// <summary>
    /// Displays the specified text in the display component.
    /// </summary>
    /// <param name="AText">
    /// The text to be displayed.
    /// </param>
    /// <returns>
    /// A string representing the text that was displayed (this can be used for confirmation or further processing).
    /// </returns>
    function Display(const AText: string): string;
    /// <summary>
    /// Streams text to the display component incrementally.
    /// </summary>
    /// <param name="AText">
    /// The text fragment to be streamed.
    /// </param>
    /// <returns>
    /// A string representing the updated display content after streaming.
    /// </returns>
    function DisplayStream(const AText: string): string;
    /// <summary>
    /// Scrolls the display to the end, ensuring that the most recent content is visible.
    /// </summary>
    procedure ScrollToEnd;
    /// <summary>
    /// Scrolls the display to the top.
    /// </summary>
    procedure ScrollToTop;
    /// <summary>
    /// Clears all content from the display.
    /// </summary>
    procedure Clear;
    /// <summary>
    /// Clears only the streamed portion of the display content.
    /// </summary>
    procedure ClearStream;
  end;

  /// <summary>
  /// Provides an interface for canceling asynchronous operations.
  /// </summary>
  /// <remarks>
  /// <para>
  /// The <c>ICancellation</c> interface defines methods for managing the cancellation state of an
  /// ongoing operation. It allows a client to request cancellation, verify if an operation has been canceled,
  /// and reset the cancellation state for reuse.
  /// </para>
  /// <para>
  /// Implementations of this interface enable graceful interruption of long-running or streaming tasks,
  /// ensuring that resources can be released properly when an operation is aborted.
  /// </para>
  /// </remarks>
  ICancellation = interface
    ['{010DE493-1C25-4CF7-8B78-045E26060EAA}']
    /// <summary>
    /// Requests the cancellation of the ongoing operation.
    /// </summary>
    procedure Cancel;
    /// <summary>
    /// Determines whether the current operation has been canceled.
    /// </summary>
    /// <returns>
    /// <c>True</c> if the operation is canceled; otherwise, <c>False</c>.
    /// </returns>
    function IsCancelled: Boolean;
    /// <summary>
    /// Resets the cancellation state, allowing a new operation to be initiated.
    /// </summary>
    procedure Reset;
  end;

  /// <summary>
  /// Provides a generic interface for a plugin that executes an asynchronous operation
  /// and returns a promise with a string result.
  /// </summary>
  /// <remarks>
  /// <para>
  /// The <c>IPromisePlugin&lt;T&gt;</c> interface defines a contract for executing asynchronous tasks
  /// that are configured using an instance of type T (typically derived from TPromiseParams). The
  /// asynchronous operation encapsulated by the plugin returns a <c>TPromise&lt;string&gt;</c>,
  /// representing the eventual outcome of the operation.
  /// </para>
  /// <para>
  /// Implementations of this interface are used to integrate external services, such as AI or web APIs,
  /// into the asynchronous processing pipeline. They abstract the details of the underlying asynchronous
  /// call, allowing the caller to work with promises for improved readability and error handling.
  /// </para>
  /// </remarks>
  IPromisePlugin<T> = interface
    ['{C476D888-B663-41A5-9C0E-034BADA6D2CE}']
    /// <summary>
    /// Executes an asynchronous operation configured with the provided parameter instance.
    /// </summary>
    /// <param name="Value">
    /// The parameter instance of type T used to set up the asynchronous operation.
    /// </param>
    /// <returns>
    /// A <c>TPromise&lt;string&gt;</c> that will eventually be fulfilled with the operation's result.
    /// </returns>
    function Execute(const Value: T): TPromise<string>;
  end;

  /// <summary>
  /// The <c>IAsyncScheduler</c> interface defines the contract for scheduling and executing
  /// asynchronous pipelines composed of multiple steps or scripts.
  /// </summary>
  /// <remarks>
  /// <para>
  /// IAsyncScheduler is responsible for orchestrating the execution of asynchronous tasks contained
  /// within a <c>TPipeline</c>. It ensures that each step is executed sequentially while handling errors
  /// via a delegate callback mechanism. Implementations of this interface should manage promise chaining,
  /// error propagation, and safe execution of asynchronous operations.
  /// </para>
  /// <para>
  /// The interface provides overloaded methods to execute a pipeline, either with an explicitly provided
  /// error handler or using a previously set delegate, giving clients flexibility in error management.
  /// </para>
  /// </remarks>
  IAsyncScheduler = interface
    ['{EA32343D-00FC-4341-95C6-FD95BF7AA9E8}']
    /// <summary>
    /// Executes the asynchronous pipeline using the specified error delegate.
    /// </summary>
    /// <param name="Scripts">
    /// The <c>TPipeline</c> containing the sequence of scripts to execute.
    /// </param>
    /// <param name="OnError">
    /// A delegate of type <c>TDelegateError</c> to handle any error messages encountered during execution.
    /// </param>
    /// <returns>
    /// A <c>TPromise&lt;string&gt;</c> that resolves with the output of the final script in the pipeline.
    /// </returns>
    function Execute(Scripts: TPipeline; const OnError: TDelegateError): TPromise<string>; overload;
    /// <summary>
    /// Executes the asynchronous pipeline using the previously set error delegate.
    /// </summary>
    /// <param name="Scripts">
    /// The <c>TPipeline</c> containing the sequence of scripts to execute.
    /// </param>
    /// <returns>
    /// A <c>TPromise&lt;string&gt;</c> that resolves with the output of the final script in the pipeline.
    /// </returns>
    function Execute(Scripts: TPipeline): TPromise<string>; overload;
    /// <summary>
    /// Sets the error delegate that will be used to handle errors during the asynchronous execution.
    /// </summary>
    /// <param name="Value">
    /// A delegate of type <c>TDelegateError</c> that processes error messages.
    /// </param>
    procedure SetDelegateError(const Value: TDelegateError);
  end;

  /// <summary>
  /// Provides an interface for managing file operations within the asynchronous promise-based workflow.
  /// </summary>
  /// <remarks>
  /// <para>
  /// IPromiseFileManager defines methods for generating a file name based on a provided prompt and for saving
  /// associated content (such as data and final text output) to files. This interface encapsulates the logic
  /// needed to create valid file names and to persist the outputs of asynchronous operations in a consistent manner.
  /// </para>
  /// <para>
  /// Implementations of this interface typically leverage AI services to generate appropriate file names and ensure
  /// that both data (e.g., research findings) and textual outputs (e.g., formatted results) are saved reliably to the file system.
  /// </para>
  /// </remarks>
  IPromiseFileManager = interface
    ['{9F2296CE-78E0-4851-87BC-DB355E8B385B}']
    /// <summary>
    /// Creates a file name based on the provided prompt and saves the associated data and text output to files.
    /// </summary>
    /// <param name="Path">
    /// The file path where the output files should be saved.
    /// </param>
    /// <param name="Prompt">
    /// The prompt text used to generate a file name.
    /// </param>
    /// <param name="Data">
    /// The data content to be saved, typically containing supplementary information or results.
    /// </param>
    /// <param name="Text">
    /// The final text output to be saved (e.g., a detailed report or formatted answer).
    /// </param>
    /// <returns>
    /// A <c>TPromise&lt;string&gt;</c> that resolves with the generated file name upon successful saving.
    /// </returns>
    function CreateFileNameAndSave(const Prompt, Data, Text: string): TPromise<string>; overload;
    /// <summary>
    /// Creates a file name based on the provided prompt and saves the associated data and text output to files.
    /// </summary>
    /// <param name="Prompt">
    /// The prompt text used to generate a file name.
    /// </param>
    /// <param name="Data">
    /// The data content to be saved.
    /// </param>
    /// <param name="Text">
    /// The final text output to be saved.
    /// </param>
    /// <returns>
    /// A <c>TPromise&lt;string&gt;</c> that resolves with the generated file name upon successful saving.
    /// </returns>
    function CreateFileNameAndSave(const Path, Prompt, Data, Text: string): TPromise<string>; overload;
  end;

var
  /// <summary>
  /// Provides cancellation control for ongoing asynchronous operations.
  /// </summary>
  Cancellation: ICancellation;
  /// <summary>
  /// An implementation of <c>IDisplayer</c> used to present streaming or static content
  /// in an Edge browser control.
  /// </summary>
  EdgeDisplayer: IDisplayer;
  /// <summary>
  /// An implementation of <c>IDisplayer</c> used to display text content within a memo component.
  /// </summary>
  MemoDisplayer: IDisplayer;
  /// <summary>
  /// An instance of <c>IPromisePlugin&lt;TPromiseParams&gt;</c> that executes asynchronous operations
  /// via the OpenAI API in streaming mode.
  /// </summary>
  OpenAIPromise: IPromisePlugin<TPromiseParams>;
  /// <summary>
  /// An instance of <c>IPromisePlugin&lt;TPromiseParams&gt;</c> that executes asynchronous operations
  /// via the OpenAI API in parallel mode.
  /// </summary>
  OpenAIParallelPromise: IPromisePlugin<TPromiseParams>;
  /// <summary>
  /// The asynchronous scheduler responsible for orchestrating the execution of pipelines
  /// composed of multiple asynchronous tasks.
  /// </summary>
  AsyncScheduler: IAsyncScheduler;
  /// <summary>
  /// The promise-based file manager used to generate file names and save output data,
  /// such as research findings and formatted text, to the file system.
  /// </summary>
  FileManager: IPromiseFileManager;

implementation

end.
