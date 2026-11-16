"""Enter release credentials locally; values are never sent to the chat."""
import tkinter as tk
from tkinter import messagebox
from secrets_store import write_secret


def main():
    root = tk.Tk()
    root.title("Factorio Mods: доступ для выпуска")
    root.resizable(False, False)
    entries = {}
    for row, (name, label) in enumerate((("github", "GitHub: Blueprint from Helmod и Nanobots3"),
                                        ("factorio", "Factorio: Upload Mods + Edit Mods"))):
        tk.Label(root, text=label).grid(row=row * 2, column=0, padx=20, pady=(12, 2), sticky="w")
        field = tk.Entry(root, width=65, show="•")
        field.grid(row=row * 2 + 1, column=0, padx=20, sticky="ew")
        entries[name] = field

    def store():
        if not all(v.get().strip() for v in entries.values()):
            messagebox.showerror("Не сохранено", "Нужны оба ключа. Не присылайте их в чат.")
            return
        for name, entry in entries.items():
            write_secret(name, entry.get().strip())
            entry.delete(0, tk.END)
        messagebox.showinfo("Готово", "Ключи зашифрованы средствами Windows для текущего пользователя.")
        root.destroy()

    tk.Button(root, text="Сохранить ключи в Windows", command=store).grid(row=5, column=0, pady=18)
    tk.Label(root, text="Ключи не попадут в исходники, ZIP, GitHub или журналы.").grid(row=6, column=0, padx=20, pady=(0, 12))
    root.mainloop()


if __name__ == "__main__":
    main()
