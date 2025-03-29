# SynkFlowAI
### Orchestrate AI Thought Chains Elegantly in Delphi

SynkFlowAI is an advanced asynchronous framework written in Delphi that orchestrates AI thought chains in an elegant and efficient way. With a dynamic [pipeline](./GLOSSARY.md#pipeline) model, a configurable sequential [scheduler](./GLOSSARY.md#scheduler), and the use of [Promises](./GLOSSARY.md#promise--tpromise), this framework meets the complex requirements of interacting with modern AI models like OpenAI.

> **This project is the logical continuation of the tutorial [CerebraChainAI](https://github.com/MaxiDonkey/CerebraChainAI).**

___
![GitHub](https://img.shields.io/badge/IDE%20Version-Delphi%2010.3/11/12-yellow)
![GitHub](https://img.shields.io/badge/platform-all%20platforms-green)
![GitHub](https://img.shields.io/badge/Updated%20on%20march%2026,%202025-blue)

- [Why This Framework?](#why-this-framework)
- [Installation](#installation)
- [Key Features](#key-features)
- [Architecture Overview](#architecture-overview)
    - [Proof by Example (included via TSampleChainExecutor)](#proof-by-example-included-via-tsamplechainexecutor)
    - [Launching an Execution (simplified snippet)](#launching-an-execution-simplified-snippet)
- [Project Structure](#project-structure)
    - [Key Diagrams](#key-diagrams)
    - [Project Dependencies](#project-dependencies)
- [Advanced Customization](#advanced-customization)
- [Limitations](#limitations)
- [Contributions](#contributions)
- [License](#license)
- [Personal Conclusion](#personal-conclusion)
- [Quick Links](#quick-links)


<br>

## Why This Framework?

In a world where artificial intelligence demands increasingly fine-tuned orchestration, `SynkFlowAI` aims to prove that it's possible to merge research and development without compromise. This project was born out of a personal challenge, within an original context, to conceptualize a solution in my own way—a process that values rigor, innovation, and deep thinking over mere recognition.

>"SynkFlowAI is not just a tool. It’s an architectural manifesto showing that structured, orchestrated, and parallel AI is possible—even in Delphi, in 2025."

- **Smart Decomposition:** Break down complex problems into logical sub-steps using [Chain-of-Thought](./GLOSSARY.md#chain-of-thought) reasoning.
- **Controlled Asynchrony:** Handle asynchronous tasks using [Promises](./GLOSSARY.md#promise--tpromise) for clean, fluid, and scalable code.
- **Parallel Orchestration:** Perform simultaneous web searches for fast and efficient data collection.
- **Dynamic Pipeline:** Organize your processing in a modular way to adapt to evolving environments.

This framework does not seek to compete with trendier languages, but to demonstrate that a modern, clear, and powerful architecture can emerge from a tool sometimes considered “traditional.” It’s like breathing new life into an old piano by composing a contemporary melody: showing that beauty and efficiency come from passion and thoughtful design—not just fashion.

<br>

## Installation

1. Clone the repository to your workstation in the directory of your choice as follows:

```bash
cd path\to\your\folder
git clone https://github.com/MaxiDonkey/SynkFlowAI
```

### Installing Dependencies

2. Perform the same steps as in point 1 to install the DelphiGenAI repository, which enables the use of the OpenAI API wrapper.

```bash
cd path\to\your\OpenAIfolder
git clone https://github.com/MaxiDonkey/DelphiGenAI
```

3. I used the ***VCL Windows Style - Windows 11 Mine Shaft 1.0 theme***, available in the GetIt Package Manager.

![Preview](https://github.com/MaxiDonkey/SynkFlowAI/blob/main/Images/themis.png?raw=true "Preview")

4.Open the `PromiseEx2.dpr` project with **Delphi**, then update the search paths in the project options as follows:

![Preview](https://github.com/MaxiDonkey/SynkFlowAI/blob/main/Images/SearchPath.png?raw=true "Preview")

5. In the runtime directory, make sure to add the 32-bit DLL named `WebView2Loader.dll`, which you can find in the DLL folder of the repository.

6. Modify the Openai key by yours :

```Delphi
const
  OpenAIKey = 'My_OpenAI_key';
```

7. Run the project. You should get the following:

![Preview](https://github.com/MaxiDonkey/SynkFlowAI/blob/main/Images/Application.png?raw=true "Preview")

<br>

## Key Features

- **`Structured Asynchrony`**  
  Advanced asynchronous task management via [Promises](./GLOSSARY.md#promise--tpromise), enabling secure and fluid task chaining.

- **`Dynamic Pipeline`**  
  A flexible and evolving processing sequence, adaptable to many use cases.

- **`Chain-of-Thought (CoT)`**  
  An approach to model complex reasoning through steps, making problems easier to decompose and understand.

- **`Modular Architecture`**  
  Includes an [IoC](./GLOSSARY.md#ioc-container) Container for dependency injection, ensuring modularity and easy testing.

- **`Native OpenAI Integration`**  
  Efficient streaming and parallel request handling to fully leverage modern AI model capabilities.

- **`Silent Mode + Streaming`**  
  Supports running chains silently (no UI) and receiving real-time streaming responses from the AI.

<br>

## Architecture Overview

### Proof by Example (included via `TSampleChainExecutor`)

**A 4-step orchestrated chain:**  
  1. Topic clarification / segmentation  
  2. Parallel documentary research (AI)  
  3. Data synthesis and structuring (JSON)  
  4. Final writing (human-like, educational tone)

**Key Modules:**  
  - **TPromise<T>** → asynchronous management with chaining  
  - **TPipeline** → groups processing steps  
  - **TSampleChainExecutor** → full execution scenario  
  - **TOpenAIPromise / TOpenAIParallelPromise** → AI API calls  
  - **TPromiseAIFileManager** → file naming + result saving

See also [key diagrams in the glossary](./GLOSSARY.md#diagrams)

<br>

### Launching an Execution (simplified snippet)

```delphi
TSampleChainExecutor.Create(
  procedure(Params: TChainExecutorParams)
  begin
    Params.Client(IoC.Resolve<IGenAI>);
    Params.Prompt('What is the impact of digital technology on education?');
    Params.Path('Results');
  end)
.Execute;
```

>What the AI does:
>  1. Clarifies the question.
>  2. Generates sub-questions and performs AI-assisted parallel web research.
>  3. Structures responses (JSON + text).
>  4. Writes a final article, exported automatically.
>  5. Automatically exports to .md and .data formats

This use case shows how a complete article can be generated automatically through 4 AI-driven steps (see full code in `TSampleChainExecutor`).

<br>

## Project Structure

|Module / Unit | Main Role |
--- | ---
|`ASync.Promise` | Core of the async engine ([TPromise](./GLOSSARY.md#promise--tpromise)) |
|`ASync.Promise.Params` | Smooth parameter handling (Input, Model...) |
|`Async.Promise.Manager` | [CoT](./GLOSSARY.md#chain-of-thought) data + models |
|`Async.Promise.Pipeline` | Groups steps into a [pipeline](./GLOSSARY.md#pipeline) |
|`OpenAI.Promise` | Sends requests to OpenAI (streaming) |
|`OpenAI.ParallelPromise` | AI-based parallel web search |
|`Sample.ChainExecutor` | Full scenario (4-step AI orchestration) |
|`OpenAI.FileManager` | Generates file names + handles saving |

<br>

### Key Diagrams

For a deeper understanding of the architecture, see the diagrams in the glossary:

- [Global Diagram (UI + Logic + Services)](./GLOSSARY.md#overview-ui--logic--services---with-parallel-web-search) – A starting point for understanding how all components interact globally.

- [Thought Chain Flow (Chain-of-Thought)](./GLOSSARY.md#thought-chain-flow--multi-step-reasoning--ai-prompting) – Helps you understand the multi-step reasoning process and how each stage contributes to the output.

- [Component Diagram (Core Services & Chain Execution)](./GLOSSARY.md#component-diagram---core-services--chain-execution) – A synthesized view of the relationships between services for easier grasp of the architecture.

- [All Diagrams](./GLOSSARY.md#diagrams) – 6 diagrams available in the glossary.

<br>

### Project Dependencies

- **IMarkDown:** For the IMarkDown interface, the solution by ***Grahame Grieve*** was used. Learn more at [delphi-markdown](https://github.com/grahamegrieve/delphi-markdown).

- **OpenAI API:** The API wrapper for `OpenAI`, developed by me, is used in this project. See: [DelphiGenAI](https://github.com/MaxiDonkey/DelphiGenAI).

- **App Skin:** The application uses the ***Windows 11 MineShaft*** skin.

<br>

## Advanced Customization

- Modify chain steps: redefine your own `TScheduleEvents` or `TSampleChainExecutor`.

- Manage injections:

```delphi
IoC.RegisterType<IDisplayer>('browser',
    function: IDisplayer
    begin
      Result := TMyDisplayer.Create(MyVisualDisplayComponent, IoC.Resolve<IMarkDown>);
    end,
    TLifetime.Transient
  );
```

- Create custom processing chains inspired by the `TSampleChainExecutor` example.

<br>

## Limitations

- This project is a `proof of concept`. Although the provided example is based on ***VCL***, it is entirely possible to develop an equivalent ***FMX*** version. To do so, simply implement the `ICancellation` and `IDisplayer` interfaces and inject your new components accordingly.

- The project currently relies on the `DelphiGenAI` wrapper, but you're free to use other wrappers available on [my GitHub](https://github.com/MaxiDonkey). As of now, only `DelphiGenAI` supports parallel request processing. However, other wrappers will be updated soon to include this feature.

- To integrate another wrapper (e.g., Gemini, Claude, Deepseek, or Mistral), refer to the structure of `OpenAI.Promise`, `OpenAI.ParallelPromise`, and `OpenAI.FileManager`, and adapt the dependency injection logic accordingly.

- `PromiseDataTrash` (refer to unit `ASync.Promise.Params`) only removes instances when the application is closed. It would be advisable to implement a mechanism that cleans up expired instances during idle periods, for example.

<br>

## Contributions

Feedback and contributions are welcome! Feel free to submit ideas or open issues to help improve the project.

<br>

## License

Distributed under the MIT License. Refer to the [MIT LICENSE](https://choosealicense.com/licenses/mit/) file for details.

<br>

## Personal Conclusion

This project represents a journey of research and experimentation. It combines rigor, innovation, and a personal approach to tackling technical challenges in a space often dominated by conventional paradigms. My goal isn’t to seek quick recognition, but to share a carefully documented proof of concept designed to inspire those who appreciate well-architected systems.

Thanks for your interest and feedback. Explore `SynkFlowAI` and see how innovation can be born from the fusion of research and development.

<br>

---

## Quick Links

- [Detailed Glossary](./GLOSSARY.md)
- [Concrete Example (TSampleChainExecutor)](./)
- [DelphiGenAI → OpenAI Wrapper](https://github.com/MaxiDonkey/DelphiGenAI)
- [MaxiDonkey on GitHub](https://github.com/MaxiDonkey?tab=repositories)
