unit OpenAI.FileManager;

interface

uses
  System.SysUtils, System.Classes, System.JSON, ASync.Promise, Async.Promise.Manager,
  Manager.Intf, GenAI, ASync.Promise.Params, Manager.IoC, ASync.Promise.Scheduler,
  Sample.SchedulerEvents;

type
  /// <summary>
  /// A file manager class that handles the creation of file names and saving of data to files.
  /// Implements the <see cref="IPromiseFileManager"/> interface to integrate with promise-based workflows.
  /// </summary>
  /// <remarks>
  /// The <see cref="TPromiseAIFileManager"/> class interacts with the OpenAI API to generate valid file names based on
  /// provided prompts and data, then saves the resulting files (such as data or final text) to the specified location.
  /// It allows asynchronous file operations, including the creation and saving of both the study data and the final text.
  /// </remarks>
  TPromiseAIFileManager = class(TInterfacedObject, IPromiseFileManager)
    /// <summary>
    /// Creates a file name based on the provided prompt and saves the data and text to files.
    /// </summary>
    /// <param name="Path">
    /// The directory path where the files will be saved. If an empty string is provided,
    /// the default path will be used.
    /// </param>
    /// <param name="Prompt">
    /// The prompt used to generate the file name. This is typically a description or input string
    /// that the system will use to derive the file name.
    /// </param>
    /// <param name="Data">
    /// The data content to be saved into a file. This could be any relevant data from the process.
    /// </param>
    /// <param name="Text">
    /// The final text content to be saved, typically the result of a reasoning or AI process.
    /// </param>
    /// <returns>
    /// Returns a <see cref="TPromise{string}"/> that resolves with the path of the saved file.
    /// </returns>
    /// <exception cref="Exception">
    /// Throws an exception if there is an error while creating the file name or saving the files.
    /// </exception>
    function CreateFileNameAndSave(const Path, Prompt, Data, Text: string): TPromise<string>; overload;
    /// <summary>
    /// Creates a file name based on the provided prompt and saves the data and text to files.
    /// This method uses the default save path.
    /// </summary>
    /// <param name="Prompt">
    /// The prompt used to generate the file name. This is typically a description or input string
    /// that the system will use to derive the file name.
    /// </param>
    /// <param name="Data">
    /// The data content to be saved into a file. This could be any relevant data from the process.
    /// </param>
    /// <param name="Text">
    /// The final text content to be saved, typically the result of a reasoning or AI process.
    /// </param>
    /// <returns>
    /// Returns a <see cref="TPromise{string}"/> that resolves with the path of the saved file.
    /// </returns>
    /// <exception cref="Exception">
    /// Throws an exception if there is an error while creating the file name or saving the files.
    /// </exception>
    function CreateFileNameAndSave(const Prompt, Data, Text: string): TPromise<string>; overload;
  end;

  /// <summary>
  /// A file manager class that generates a valid file name based on a provided prompt and saves data and text to files.
  /// </summary>
  /// <remarks>
  /// The <see cref="TOpenAIFileManager"/> class interacts with the OpenAI API to create valid file names based on the prompt
  /// and saves the generated files to the specified path. It handles both data and text saving, ensuring files are properly
  /// named and stored based on the result of AI-driven processes.
  /// </remarks>
  TOpenAIFileManager = class
  const
    Pattern =
      'From the sentence: %s' + sLineBreak +
      'Create a valid Windows file name without extension' +
      '- replace underscores with spaces' +
      '- the result must be formatted only as follows: ' +
      '{"FileName": "the file name"} without JSON container';
  private
    LocalParams: TPromiseParams;
  public
    /// <summary>
    /// Builds the prompt used to generate a valid file name from a given source string.
    /// </summary>
    /// <param name="Source">
    /// The source string (typically a sentence or input) that is used to generate a valid file name.
    /// </param>
    /// <returns>
    /// Returns a formatted string that contains the instructions to be used by OpenAI to generate a valid file name.
    /// </returns>
    function BuildPrompt(const Source: string): string;
    /// <summary>
    /// Extracts the file name from the JSON response provided by OpenAI's API.
    /// </summary>
    /// <param name="JSON">
    /// The JSON response string returned by the OpenAI API, which contains the generated file name.
    /// </param>
    /// <returns>
    /// Returns the extracted file name from the JSON response.
    /// </returns>
    /// <exception cref="Exception">
    /// Throws an exception if the JSON response is not valid or does not contain the expected file name field.
    /// </exception>
    function GetFileName(const JSON: string): string;
    /// <summary>
    /// Saves the given content to a file with the specified file name.
    /// </summary>
    /// <param name="FileName">
    /// The full file name (including path) where the content will be saved.
    /// </param>
    /// <param name="Content">
    /// The content (data or text) to be saved to the file.
    /// </param>
    procedure SaveToFile(const FileName: string; const Content: string);
    /// <summary>
    /// Creates a valid file name using OpenAI's model based on the provided prompt, and saves data and text into files.
    /// </summary>
    /// <param name="Path">
    /// The directory path where the files will be saved. If an empty string is passed, the default path is used.
    /// </param>
    /// <param name="Prompt">
    /// The prompt used to generate the file name. Typically a sentence or description that OpenAI will use to create the file name.
    /// </param>
    /// <param name="Data">
    /// The data content to be saved in a file. This can be any relevant information generated by the process.
    /// </param>
    /// <param name="Text">
    /// The final text content to be saved, usually the result of a generative process or reasoning.
    /// </param>
    /// <returns>
    /// Returns a promise that resolves with the generated file name or the path where the file is saved.
    /// </returns>
    /// <exception cref="Exception">
    /// Throws an exception if there is an issue with the file creation, name generation, or saving process.
    /// </exception>
    function CreateFileNameAndSave(const Path, Prompt, Data, Text: string): TPromise<string>; overload;
    /// <summary>
    /// Creates a valid file name using OpenAI's model based on the provided prompt and saves the data and text to files.
    /// This method uses the default path for saving the files.
    /// </summary>
    /// <param name="Prompt">
    /// The prompt used to generate the file name. Typically a sentence or description that OpenAI will use to create the file name.
    /// </param>
    /// <param name="Data">
    /// The data content to be saved in a file. This can be any relevant information generated by the process.
    /// </param>
    /// <param name="Text">
    /// The final text content to be saved, usually the result of a generative process or reasoning.
    /// </param>
    /// <returns>
    /// Returns a promise that resolves with the generated file name or the path where the file is saved.
    /// </returns>
    /// <exception cref="Exception">
    /// Throws an exception if there is an issue with the file creation, name generation, or saving process.
    /// </exception>
    function CreateFileNameAndSave(const Prompt, Data, Text: string): TPromise<string>; overload;
    constructor Create;
  end;

implementation

uses
  System.IOUtils;

{ TOpenAIFileManager }

constructor TOpenAIFileManager.Create;
begin
  inherited Create;

  {--- This instance is automatically destroy by the garbage collector }
  PromiseDataTrash.Add(Self);
end;

function TOpenAIFileManager.CreateFileNameAndSave(const Prompt, Data,
  Text: string): TPromise<string>;
begin
  Result := CreateFileNameAndSave(EmptyStr, Prompt, Data, Text);
end;

function TOpenAIFileManager.CreateFileNameAndSave(const Path, Prompt, Data, Text: string): TPromise<string>;
begin
  Result := TScheduleEvents.Create(
        procedure (Params: TPromiseParams)
        begin
          Params.Client(IoC.Resolve<IGenAI>);
          Params.Model('gpt-4o-mini');
          Params.Input(BuildPrompt(Prompt));
          Params.SilentMode(True);
          LocalParams := Params;
        end)
    .Execute
        .&Then<string>(
            function (Value: string): string
            begin
              {--- The model assigns the file name from the prompt }
              Result := GetFileName(LocalParams.GetOutput);

              {--- Concatenate the file name and the path if it exists }
              if not Path.Trim.IsEmpty then
                begin
                  {--- Create folder "Path" when not exists }
                  if not TDirectory.Exists(Path.Trim) then
                    TDirectory.CreateDirectory(Path.Trim);

                  {--- Finalize filename construction }
                  Result := Path.TrimRight(['\']) + '\' + Result.TrimLeft(['\']);
                end;

              {--- Save study and web research data to a file with the .data extension }
              if not Data.Trim.IsEmpty then
                SaveToFile(Result + '.data', Data.Trim);

              {--- Save the text developed from the study and web research }
              if not Text.Trim.IsEmpty then
                SaveToFile(Result + '.md', Text.Trim);
            end)
        .&Catch(
          procedure(E: Exception)
          begin
            try
              EdgeDisplayer.Display(E.Message);
            finally
              E.Free;
            end;
          end);
end;

function TOpenAIFileManager.GetFileName(const JSON: string): string;
begin
  var JSONObject := TJSONObject.ParseJSONValue(JSON) as TJSONObject;
  try
    if Assigned(JSONObject) then
      begin
        Result := JSONObject.GetValue<string>('FileName');
      end
    else
      raise Exception.Create('JSON filename : Parsing error ');
  finally
    JSONObject.Free;
  end;
end;

function TOpenAIFileManager.BuildPrompt(const Source: string): string;
begin
  Result := Format(Pattern, [Source]);
end;

procedure TOpenAIFileManager.SaveToFile(const FileName, Content: string);
begin
  var Stream := TStringStream.Create(Content, TEncoding.UTF8);
  try
    Stream.SaveToFile(FileName);
  finally
    Stream.Free;
  end;
end;

{ TPromiseAIFileManager }

function TPromiseAIFileManager.CreateFileNameAndSave(const Path, Prompt, Data,
  Text: string): TPromise<string>;
begin
  Result := TOpenAIFileManager.Create.CreateFileNameAndSave(Path, Prompt, Data, Text);
end;

function TPromiseAIFileManager.CreateFileNameAndSave(const Prompt, Data,
  Text: string): TPromise<string>;
begin
  Result := TOpenAIFileManager.Create.CreateFileNameAndSave(Prompt, Data, Text);
end;

end.
