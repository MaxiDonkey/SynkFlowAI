/// <summary>
/// The <c>Manager.IoC</c> unit implements a basic Inversion of Control (IoC) container that
/// provides dependency injection capabilities for Delphi applications.
/// </summary>
/// <remarks>
/// <para>
/// This unit defines key components for managing dependency registrations and resolutions:
/// </para>
/// <para>
/// - <c>TLifetime</c>: An enumeration that specifies whether an instance should be created as a transient object
/// or maintained as a singleton throughout the application's lifetime.
/// </para>
/// <para>
/// - <c>TRegistrationInfo</c>: A record that stores registration details for a type, including the factory method,
/// the instance (for singletons), and the lifetime setting.
/// </para>
/// <para>
/// - <c>TIoCContainer</c>: The main container class that maintains a registry of dependencies and provides methods
/// to register and resolve interface implementations based on their type and an optional identifier.
/// </para>
/// <para>
/// This IoC container enables decoupled and modular design by allowing objects to be instantiated and managed
/// at runtime. It supports both transient and singleton lifetimes, facilitating flexible dependency management
/// across the application.
/// </para>
/// </remarks>
unit Manager.IoC;

interface

uses
  System.SysUtils, System.Classes, System.TypInfo, System.Generics.Collections;

type
  /// <summary>
  /// Definition of the lifecycle.
  /// </summary>
  TLifetime = (
    /// <summary>
    /// Instances can be recreated if needed.
    /// </summary>
    Transient,
    /// <summary>
    /// Remains constant throughout the application.
    /// </summary>
    Singleton
  );

  /// <summary>
  /// Storage structure for a registration record.
  /// </summary>
  TRegistrationInfo = record
    Instance: IInterface;               // For singletons
    FactoryMethod: TFunc<IInterface>;   // Function returning an interface
    Lifetime: TLifetime;
  end;

  /// <summary>
  /// The <c>TIoCContainer</c> class implements a simple Inversion of Control (IoC) container
  /// for managing dependency registrations and resolutions in Delphi applications.
  /// </summary>
  /// <remarks>
  /// <para>
  /// TIoCContainer maintains an internal registry that maps interface types (optionally keyed
  /// by a name) to registration records containing factory methods and lifetime settings. This allows
  /// for flexible creation and management of object instances at runtime.
  /// </para>
  /// <para>
  /// The container supports two lifetimes:
  /// <c>Transient</c>: A new instance is created every time the dependency is resolved.
  /// <c>Singleton</c>: A single instance is created and shared throughout the application's lifetime.
  /// </para>
  /// <para>
  /// Use the <c>RegisterType</c> methods to register a dependency, and the <c>Resolve</c> method to retrieve
  /// an instance of a registered dependency.
  /// </para>
  /// </remarks>
  TIoCContainer = class
  private
    // Using a key of type string combining the interface name and an optional identifier
    FRegistry: TDictionary<string, TRegistrationInfo>;
    /// <summary>
    /// Generates a unique registration key for the given interface type and an optional identifier.
    /// </summary>
    /// <typeparam name="T">
    /// The interface type for which the key is generated.
    /// </typeparam>
    /// <param name="AName">
    /// An optional name to differentiate multiple registrations of the same interface.
    /// </param>
    /// <returns>
    /// A string representing the unique key for the registration.
    /// </returns>
    function GetRegistrationKey<T>(const AName: string): string;
  public
    constructor Create;
    destructor Destroy; override;
    /// <summary>
    /// Registers a dependency for the interface type T using a factory lambda function.
    /// </summary>
    /// <typeparam name="T">
    /// The interface type to register.
    /// </typeparam>
    /// <param name="AName">
    /// An optional identifier to differentiate multiple registrations for the same interface.
    /// </param>
    /// <param name="AFactory">
    /// A lambda function that creates and returns an instance of type T.
    /// </param>
    /// <param name="ALifetime">
    /// Specifies the lifetime of the instance; use <c>Transient</c> for a new instance on each resolve,
    /// or <c>Singleton</c> to share a single instance.
    /// </param>
    procedure RegisterType<T: IInterface>(const AName: string; AFactory: TFunc<T>; ALifetime: TLifetime = TLifetime.Transient); overload;
    /// <summary>
    /// Registers a dependency for the interface type T using a factory lambda function.
    /// This overload does not require an identifier.
    /// </summary>
    /// <typeparam name="T">
    /// The interface type to register.
    /// </typeparam>
    /// <param name="AFactory">
    /// A lambda function that creates and returns an instance of type T.
    /// </param>
    /// <param name="ALifetime">
    /// Specifies the lifetime of the instance; use <c>Transient</c> for a new instance on each resolve,
    /// or <c>Singleton</c> to share a single instance.
    /// </param>
    procedure RegisterType<T: IInterface>(AFactory: TFunc<T>; ALifetime: TLifetime = TLifetime.Transient); overload;
    /// <summary>
    /// Resolves an instance of the registered interface type T.
    /// </summary>
    /// <typeparam name="T">
    /// The interface type to resolve.
    /// </typeparam>
    /// <param name="AName">
    /// An optional identifier that must match the one used during registration.
    /// </param>
    /// <returns>
    /// An instance of type T. If the dependency was registered as a singleton, the same instance is returned
    /// on subsequent calls. For transient registrations, a new instance is created.
    /// </returns>
    function Resolve<T: IInterface>(const AName: string = ''): T;
  end;

var
  /// <summary>
  /// A global instance of the <c>TIoCContainer</c> used for dependency injection across the application.
  /// </summary>
  /// <remarks>
  /// This variable holds the container that manages registrations and resolutions of dependencies.
  /// It is instantiated during application initialization and released during finalization,
  /// ensuring that all registered services are available throughout the application's lifetime.
  /// </remarks>
  IoC: TIoCContainer;

implementation

{ TIoCContainer }

constructor TIoCContainer.Create;
begin
  inherited Create;
  FRegistry := TDictionary<string, TRegistrationInfo>.Create;
end;

destructor TIoCContainer.Destroy;
begin
  FRegistry.Free;
  inherited;
end;

function TIoCContainer.GetRegistrationKey<T>(const AName: string): string;
begin
  Result := GetTypeName(TypeInfo(T));
  if not AName.Trim.IsEmpty then
    Result := Result + '|' + AName;
end;

procedure TIoCContainer.RegisterType<T>(const AName: string; AFactory: TFunc<T>; ALifetime: TLifetime);
var
  RegistrationKey: string;
  Registration: TRegistrationInfo;
begin
  RegistrationKey := GetRegistrationKey<T>(AName);

  Registration.Lifetime := ALifetime;
  Registration.Instance := nil;
  {--- Wrapping the lambda to return an IInterface }
  Registration.FactoryMethod := function: IInterface
  begin
    Result := AFactory();
  end;

  FRegistry.Add(RegistrationKey, Registration);
end;

procedure TIoCContainer.RegisterType<T>(AFactory: TFunc<T>;
  ALifetime: TLifetime);
begin
  RegisterType<T>(EmptyStr, AFactory, ALifetime);
end;

function TIoCContainer.Resolve<T>(const AName: string): T;
var
  RegistrationKey: string;
  Registration: TRegistrationInfo;
  Intf: IInterface;
begin
  RegistrationKey := GetRegistrationKey<T>(AName);

  if not FRegistry.TryGetValue(RegistrationKey, Registration) then
    raise Exception.CreateFmt('Type %s not registered in the IoC container with the name "%s"', [GetTypeName(TypeInfo(T)), AName]);

  case Registration.Lifetime of
    TLifetime.Singleton:
      begin
        if Registration.Instance = nil then
        begin
          Registration.Instance := Registration.FactoryMethod();
          {--- Update the record in the dictionary }
          FRegistry[RegistrationKey] := Registration;
        end;
        Intf := Registration.Instance;
      end;
    TLifetime.Transient:
      Intf := Registration.FactoryMethod();
  end;

  {--- Convert to type T (ensures the object supports the interface) }
  Result := T(Intf);
end;

initialization
  IoC := TIoCContainer.Create;
finalization
  IoC.Free;
end.

