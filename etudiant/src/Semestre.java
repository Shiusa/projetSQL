public enum Semestre {
    Q1("Q1"),
    Q2("Q2");

    private String name;

    Semestre(String name) {
        this.name = name;
    }

    public String getName() {
        return name;
    }
}
