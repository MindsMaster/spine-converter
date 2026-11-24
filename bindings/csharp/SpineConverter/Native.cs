using System.Runtime.InteropServices;

namespace SpineConverter
{
    /// <summary>Members mirror include/spine_converter.h</summary>
    internal static unsafe class Native
    {
#if UNITY_IOS && !UNITY_EDITOR
        /// <summary>Static plugins link into the iOS player</summary>
        public const string Library = "__Internal";
#else
        public const string Library = "spine_converter";
#endif
        public const uint AbiVersion = 1;

        [StructLayout(LayoutKind.Sequential)]
        public struct Options
        {
            public uint StructSize;
            public byte* TargetVersion;
            public Format TargetFormat;
            public uint Flags;
            public byte* Atlas;
            public nuint AtlasLength;
        }

        [StructLayout(LayoutKind.Sequential)]
        public struct DetectResult
        {
            public Format Format;
            public fixed byte Version[32];
            public ushort Major;
            public ushort Minor;
            public ushort Patch;
        }

        [DllImport(Library, EntryPoint = "spc_abi_version", CallingConvention = CallingConvention.Cdecl)]
        public static extern uint AbiVersionOf();

        [DllImport(Library, EntryPoint = "spc_library_version", CallingConvention = CallingConvention.Cdecl)]
        public static extern byte* LibraryVersion();

        [DllImport(Library, EntryPoint = "spc_status_string", CallingConvention = CallingConvention.Cdecl)]
        public static extern byte* StatusString(Status status);

        [DllImport(Library, EntryPoint = "spc_detect", CallingConvention = CallingConvention.Cdecl)]
        public static extern Status Detect(byte* data, nuint length, DetectResult* result);

        [DllImport(Library, EntryPoint = "spc_convert", CallingConvention = CallingConvention.Cdecl)]
        public static extern Status Convert(byte* data, nuint length, Options* options, void* allocator, nint* result);

        [DllImport(Library, EntryPoint = "spc_result_status", CallingConvention = CallingConvention.Cdecl)]
        public static extern Status ResultStatus(nint result);

        [DllImport(Library, EntryPoint = "spc_result_data", CallingConvention = CallingConvention.Cdecl)]
        public static extern byte* ResultData(nint result, nuint* length);

        [DllImport(Library, EntryPoint = "spc_result_report", CallingConvention = CallingConvention.Cdecl)]
        public static extern byte* ResultReport(nint result, nuint* length);

        [DllImport(Library, EntryPoint = "spc_result_loss_count", CallingConvention = CallingConvention.Cdecl)]
        public static extern nuint ResultLossCount(nint result);

        [DllImport(Library, EntryPoint = "spc_result_max_impact", CallingConvention = CallingConvention.Cdecl)]
        public static extern Impact ResultMaxImpact(nint result);

        [DllImport(Library, EntryPoint = "spc_result_remedy_count", CallingConvention = CallingConvention.Cdecl)]
        public static extern nuint ResultRemedyCount(nint result, Remedy remedy);

        [DllImport(Library, EntryPoint = "spc_result_error", CallingConvention = CallingConvention.Cdecl)]
        public static extern byte* ResultError(nint result);

        [DllImport(Library, EntryPoint = "spc_result_free", CallingConvention = CallingConvention.Cdecl)]
        public static extern void ResultFree(nint result);
    }
}
